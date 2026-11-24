# frozen_string_literal: true

RSpec.describe EnterpriseContactMessagesController do
  include ActiveJob::TestHelper

  let!(:enterprise) do
    create(:distributor_enterprise, name: "Fred's Farm", email_address: "fred@example.com")
  end
  let(:message_params) do
    { name: "Jo Shopper", email: "jo@example.org", message: "Do you have eggs?" }
  end

  # The rate limit counts requests in the Redis cache, which outlives examples.
  before { Rails.cache.delete_matched("rate-limit:enterprise_contact_messages*") }

  def post_message(params = message_params, honeypot: nil)
    request_params = { enterprise_contact_message: params }
    request_params[honeypot_field] = honeypot if honeypot

    post enterprise_contact_message_path(enterprise), params: request_params, as: :turbo_stream
  end

  # invisible_captcha names its honeypot field randomly unless configured.
  def honeypot_field
    InvisibleCaptcha.honeypots.first
  end

  describe "GET new" do
    it "shows the form without the enterprise's email address" do
      get new_enterprise_contact_message_path(enterprise)

      expect(response).to have_http_status :ok
      expect(response.body).to include "Contact Fred&#39;s Farm"
      expect(response.body).not_to include "fred@example.com"
      expect(response.body).not_to include "fred@example.com".reverse
    end

    it "is not found for an enterprise without an email address" do
      enterprise.update!(email_address: "")

      get new_enterprise_contact_message_path(enterprise)

      expect(response).to have_http_status :not_found
    end
  end

  describe "POST create" do
    it "emails the message to the enterprise" do
      expect {
        perform_enqueued_jobs { post_message }
      }.to change { ActionMailer::Base.deliveries.count }.by(1)

      expect(response).to have_http_status :ok
      expect(response.body).to include "your message has been sent to Fred&#39;s Farm"
      expect(response.body).not_to include "fred@example.com"

      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to eq ["fred@example.com"]
      expect(mail.reply_to).to eq ["jo@example.org"]
    end

    it "shows errors and sends nothing when the message is invalid" do
      expect {
        post_message(message_params.merge(email: "not an email", message: ""))
      }.not_to have_enqueued_mail(EnterpriseMailer, :contact_message)

      expect(response).to have_http_status :unprocessable_entity
      expect(response.body).to include "can&#39;t be blank"
      expect(response.body).to include "Jo Shopper"
    end

    it "pretends to succeed but sends nothing when a bot fills in the honeypot" do
      expect {
        post_message(honeypot: "spam")
      }.not_to have_enqueued_mail(EnterpriseMailer, :contact_message)

      expect(response).to have_http_status :ok
      expect(response.body).to include "your message has been sent"
    end

    it "refuses to send more than five messages an hour from one visitor" do
      5.times { post_message }

      expect {
        post_message
      }.not_to have_enqueued_mail(EnterpriseMailer, :contact_message)

      expect(response).to have_http_status :too_many_requests
      expect(response.body).to include "Please try again later"
    end

    it "is not found for an enterprise without an email address" do
      enterprise.update!(email_address: nil)

      expect {
        post_message
      }.not_to have_enqueued_mail(EnterpriseMailer, :contact_message)

      expect(response).to have_http_status :not_found
    end
  end
end
