class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: -> { new_record? || !password.nil? }
  validates :first_name, presence: true, length: { minimum: 2 }, if: -> { first_name.present? }
  validates :last_name, presence: true, length: { minimum: 2 }, if: -> { last_name.present? }

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :first_name, with: ->(name) { name&.strip&.titleize }
  normalizes :last_name, with: ->(name) { name&.strip&.titleize }
end
