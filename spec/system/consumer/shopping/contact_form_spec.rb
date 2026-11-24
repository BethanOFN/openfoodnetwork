# frozen_string_literal: true

require 'system_helper'

RSpec.describe "Contacting an enterprise from its shopfront" do
  let(:distributor) do
    create(:distributor_enterprise, name: "Fred's Farm", email_address: "fred@example.com")
  end

  before do
    Rails.cache.delete_matched("rate-limit:enterprise_contact_messages*")
  end

  it "sends a message without revealing the email address" do
    visit enterprise_shop_path(distributor)
    within(".tab-buttons") { click_link "Contact" }

    expect(page.html).not_to include "fred@example.com"
    expect(page.html).not_to include "fred@example.com".reverse

    fill_in "Your name", with: "Jo Shopper"
    fill_in "Your email", with: "jo@example.org"
    fill_in "Message", with: "Do you have eggs this week?"

    expect {
      click_button "Send message"
      expect(page).to have_content "your message has been sent to Fred's Farm"
    }.to have_enqueued_mail(EnterpriseMailer, :contact_message)
  end

  it "shows errors without losing what was typed" do
    visit enterprise_shop_path(distributor)
    within(".tab-buttons") { click_link "Contact" }

    fill_in "Your name", with: "Jo Shopper"
    fill_in "Your email", with: "jo@example"
    fill_in "Message", with: "Hello"
    click_button "Send message"

    expect(page).to have_content "is invalid"
    expect(page).to have_field "Your name", with: "Jo Shopper"
  end

  it "has no form when the enterprise has no email address" do
    distributor.update!(email_address: nil)

    visit enterprise_shop_path(distributor)
    within(".tab-buttons") { click_link "Contact" }

    expect(page).not_to have_button "Send message"
  end
end
