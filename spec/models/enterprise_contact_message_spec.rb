# frozen_string_literal: true

RSpec.describe EnterpriseContactMessage do
  subject(:contact_message) do
    described_class.new(name: "Jo", email: "jo@example.org", message: "Hello")
  end

  it { is_expected.to be_valid }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:email) }
  it { is_expected.to validate_presence_of(:message) }
  it { is_expected.to validate_length_of(:name).is_at_most(100) }
  it { is_expected.to validate_length_of(:message).is_at_most(2000) }

  it "requires a valid email address" do
    contact_message.email = "jo at example"

    expect(contact_message).not_to be_valid
  end
end
