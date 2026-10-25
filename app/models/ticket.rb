class Ticket < ApplicationRecord
  PRIORITIES = %w[urgent high normal low].freeze
  ACTIVE_STATUSES = %w[new open pending].freeze

  # DURUM AKIŞI: new > open > pending > solved > closed
  # Burada olmayan bir geçiş transition_to! içinde reddedilir.
  TRANSITIONS = {
    "new"     => %w[open pending solved],
    "open"    => %w[pending solved],
    "pending" => %w[open solved],
    "solved"  => %w[open closed],
    "closed"  => []
  }.freeze
  STATUSES = TRANSITIONS.keys.freeze

  # ZAMAN KURALI: çözülen talep, müşteri 4 gün içinde yazmazsa kendiliğinden kapanır.
  AUTO_CLOSE_AFTER = 4.days

  class InvalidTransition < StandardError; end

  belongs_to :assignee, class_name: "Agent", optional: true
  has_many :comments, -> { order(:created_at, :id) }, dependent: :destroy
  has_many :sla_events, -> { order(:created_at, :id) }, dependent: :destroy

  has_secure_token :token

  validates :subject, :description, :requester_name, presence: true
  validates :requester_email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :priority, inclusion: { in: PRIORITIES }
  validates :status, inclusion: { in: STATUSES }

  before_validation :set_first_response_due_at, on: :create

  scope :active, -> { where(status: ACTIVE_STATUSES) }
  scope :awaiting_first_response, -> { active.where(first_responded_at: nil) }
  scope :by_deadline, -> { order(:first_response_due_at, :id) }

  def self.auto_close_solved!(now = Time.current)
    where(status: "solved").where(solved_at: ..(now - AUTO_CLOSE_AFTER)).find_each.count do |ticket|
      ticket.transition_to!("closed", at: now)
    end
  end

  def active?
    ACTIVE_STATUSES.include?(status)
  end

  def can_transition_to?(new_status)
    TRANSITIONS.fetch(status).include?(new_status)
  end

  def allowed_transitions
    TRANSITIONS.fetch(status)
  end

  def transition_to!(new_status, at: Time.current)
    unless can_transition_to?(new_status)
      raise InvalidTransition, "#{status} → #{new_status} geçişi yapılamaz"
    end

    self.status = new_status
    case new_status
    when "solved" then self.solved_at = at
    when "closed" then self.closed_at = at
    when "open"   then self.solved_at = nil
    end
    save!
  end

  # Temsilci yanıtı: ilk yanıtsa SLA'yı durdurur, talebi temsilciye atar,
  # istenen duruma (varsayılan: açık) geçirir.
  def reply_as_agent!(agent, body, status: nil, at: Time.current)
    raise InvalidTransition, "Kapanmış talebe yanıt yazılamaz" if self.status == "closed"

    transaction do
      comments.create!(author_type: "agent", author_name: agent.name, body: body)
      self.first_responded_at ||= at
      self.assignee ||= agent
      target = status.presence || (self.status == "new" ? "open" : self.status)
      target == self.status ? save! : transition_to!(target, at: at)
    end
  end

  # Müşteri yanıtı: beklemede ya da çözülmüş talebi yeniden açar.
  def reply_as_requester!(body)
    raise InvalidTransition, "Kapanmış talebe yanıt yazılamaz" if status == "closed"

    transaction do
      comments.create!(author_type: "requester", author_name: requester_name, body: body)
      %w[pending solved].include?(status) ? transition_to!("open") : touch
    end
  end

  # :met, :missed, :on_track, :at_risk, :breached ya da :none (yanıtsız çözülmüş/kapanmış)
  def sla_state(now = Time.current)
    if first_responded_at
      first_responded_at <= first_response_due_at ? :met : :missed
    elsif !active?
      :none
    elsif now >= first_response_due_at
      :breached
    elsif first_response_due_at - now <= SlaPolicy.warning_window(priority)
      :at_risk
    else
      :on_track
    end
  end

  def seconds_remaining(now = Time.current)
    (first_response_due_at - now).to_i
  end

  private

  def set_first_response_due_at
    return if priority.blank? || !PRIORITIES.include?(priority)

    self.first_response_due_at ||= SlaPolicy.due_at(priority, from: created_at || Time.current)
  end
end
