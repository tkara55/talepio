class Agent < ApplicationRecord
  has_many :assigned_tickets, class_name: "Ticket", foreign_key: :assignee_id, inverse_of: :assignee, dependent: :nullify

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true

  # Açık iş yükü en az olan temsilci (eşitlikte en eski kayıt).
  def self.least_loaded
    all.min_by { |agent| [ agent.assigned_tickets.active.count, agent.id ] }
  end

  def initials
    name.split.map { |part| part[0] }.join.first(2).upcase
  end
end
