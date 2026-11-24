# frozen_string_literal: true

# A message sent by a visitor to an enterprise through its public contact form.
#
# This lets enterprises be contacted without publishing their email address
# where humans and bots can harvest it.
class EnterpriseContactMessage
  include ActiveModel::Model
  include ActiveModel::Attributes

  MESSAGE_MAX_LENGTH = 2000

  attribute :name, :string
  attribute :email, :string
  attribute :message, :string

  validates :name, presence: true, length: { maximum: 100 }
  validates :email, presence: true, 'valid_email_2/email': true
  validates :message, presence: true, length: { maximum: MESSAGE_MAX_LENGTH }
end
