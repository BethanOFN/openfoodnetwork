# frozen_string_literal: true

RSpec.describe EnterpriseMailer do
  let(:enterprise) { build(:enterprise, name: "Fred's Farm") }
  let(:order) { build(:order_with_distributor) }

  describe "#welcome" do
    subject(:mail) { described_class.welcome(enterprise) }

    it "sends a welcome email when given an enterprise" do
      expect(mail.subject)
        .to eq "Fred's Farm is now on OFN Demo Site"
    end

    it "does not set a reply-to email" do
      expect(mail.reply_to).to eq nil
    end

    context "white labelling" do
      it_behaves_like 'email with inactive white labelling', :mail
      it_behaves_like 'non-customer facing email with active white labelling', :mail
    end
  end

  describe "#contact_message" do
    subject(:mail) { described_class.contact_message(enterprise, message) }
    let(:enterprise) { build(:enterprise, name: "Fred's Farm", email_address: "fred@example.com") }
    let(:message) do
      { "name" => "Jo <b>Shopper</b>", "email" => "jo@example.org", "message" => "Any eggs?" }
    end

    it "sends the message to the enterprise's email address" do
      expect(mail.to).to eq ["fred@example.com"]
      expect(mail.subject).to eq "New message from Jo <b>Shopper</b> via OFN Demo Site"
    end

    it "lets the enterprise reply directly to the sender" do
      expect(mail.reply_to).to eq ["jo@example.org"]
    end

    it "includes the message, escaping what the sender typed" do
      body = mail.body.encoded

      expect(body).to include "Any eggs?"
      expect(body).to include "jo@example.org"
      expect(body).to include "Jo &lt;b&gt;Shopper&lt;/b&gt;"
    end
  end

  describe "#manager_invitation" do
    subject(:mail) { described_class.manager_invitation(enterprise, user) }
    let(:user) { build(:user) }

    it "should send a manager invitation email when given an enterprise and user" do
      expect(mail.subject).to eq "Fred's Farm has invited you to be a manager"
    end

    it "sets a reply-to of the enterprise email" do
      expect(mail.reply_to).to eq([enterprise.contact.email])
    end

    context "white labelling" do
      it_behaves_like 'email with inactive white labelling', :mail
      it_behaves_like 'non-customer facing email with active white labelling', :mail
    end
  end
end
