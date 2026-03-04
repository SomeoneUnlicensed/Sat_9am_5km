class Kudo < ApplicationRecord
  belongs_to :athlete
  belongs_to :result, counter_cache: true

  validates :athlete_id, uniqueness: { scope: :result_id }
end
