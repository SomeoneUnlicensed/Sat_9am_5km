# frozen_string_literal: true

class WalletPassRegistration < ApplicationRecord
  belongs_to :athlete

  validates :device_library_identifier, presence: true
  validates :push_token, presence: true
  validates :serial_number, presence: true
  validates :pass_type_identifier, presence: true
  validates :auth_token, presence: true
  validates :device_library_identifier, uniqueness: { scope: :serial_number }

  before_validation :generate_auth_token, on: :create

  def self.ransackable_attributes(_auth_object = nil)
    %w[athlete_id auth_token created_at device_library_identifier id pass_type_identifier push_token serial_number updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[athlete]
  end

  private

  def generate_auth_token
    self.auth_token ||= SecureRandom.hex(16)
  end
end
