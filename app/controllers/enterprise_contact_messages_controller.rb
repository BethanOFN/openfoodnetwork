# frozen_string_literal: true

# Lets visitors message an enterprise without the enterprise's email address
# ever being sent to the browser.
class EnterpriseContactMessagesController < BaseController
  # Runs before the spam checks below, so their handlers can render the form.
  prepend_before_action :load_enterprise

  invisible_captcha only: :create, on_spam: :reject_spam, on_timestamp_spam: :reject_too_fast
  rate_limit to: 5, within: 1.hour, only: :create, with: -> { reject_rate_limited }

  def new
    @enterprise_contact_message = EnterpriseContactMessage.new
  end

  def create
    @enterprise_contact_message = EnterpriseContactMessage.new(contact_message_params)

    if @enterprise_contact_message.valid?
      EnterpriseMailer.contact_message(@enterprise, @enterprise_contact_message.attributes)
        .deliver_later
      render_form(:ok, sent: true)
    else
      render_form(:unprocessable_entity)
    end
  end

  private

  def load_enterprise
    @enterprise = Enterprise.activated.find_by(permalink: params[:enterprise_id])

    raise ActiveRecord::RecordNotFound if @enterprise&.email_address.blank?
  end

  def contact_message_params
    params.expect(enterprise_contact_message: [:name, :email, :message])
  end

  def render_form(status, sent: false, alert: nil)
    @enterprise_contact_message ||= EnterpriseContactMessage.new(contact_message_params)

    render turbo_stream: turbo_stream.update(
      helpers.dom_id(@enterprise, :contact_message),
      partial: "enterprise_contact_messages/form",
      locals: {
        enterprise: @enterprise, contact_message: @enterprise_contact_message, sent:, alert:
      }
    ), status:
  end

  # The honeypot field was filled in, so this is a bot. Look successful so it
  # doesn't learn to avoid the trap, but send nothing.
  def reject_spam
    render_form(:ok, sent: true)
  end

  def reject_too_fast
    render_form(:unprocessable_entity, alert: InvisibleCaptcha.timestamp_error_message)
  end

  def reject_rate_limited
    render_form(:too_many_requests,
                alert: t("enterprise_contact_messages.form.rate_limited"))
  end
end
