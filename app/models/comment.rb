class Comment < ApplicationRecord
  AUTHOR_TYPES = %w[agent requester].freeze

  belongs_to :ticket, touch: true

  validates :body, :author_name, presence: true
  validates :author_type, inclusion: { in: AUTHOR_TYPES }

  def from_agent?
    author_type == "agent"
  end
end
