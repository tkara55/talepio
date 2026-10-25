class SlaEvent < ApplicationRecord
  KINDS = %w[warning breach].freeze

  belongs_to :ticket

  validates :kind, inclusion: { in: KINDS }
  validates :kind, uniqueness: { scope: :ticket_id }
end
