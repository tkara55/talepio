class TicketsController < ApplicationController
  before_action :require_agent
  before_action :sweep_sla_radar

  VIEWS = {
    "aktif"     => "Aktif",
    "benim"     => "Bana atanan",
    "atanmamis" => "Atanmamış",
    "cozuldu"   => "Çözüldü",
    "kapandi"   => "Kapandı"
  }.freeze

  def index
    @view = VIEWS.key?(params[:view]) ? params[:view] : "aktif"
    @tickets = scoped_tickets.includes(:assignee)
    @now = Time.current
    @radar = Ticket.awaiting_first_response.group_by { |t| t.sla_state(@now) }.transform_values(&:size)
    @events = SlaEvent.includes(:ticket).order(created_at: :desc, id: :desc).limit(8)
  end

  def show
    @ticket = Ticket.includes(:comments, :sla_events, :assignee).find(params[:id])
    @agents = Agent.order(:name)
    @now = Time.current
  end

  private

  def scoped_tickets
    case @view
    when "benim"     then Ticket.active.where(assignee: current_agent).by_deadline
    when "atanmamis" then Ticket.active.where(assignee_id: nil).by_deadline
    when "cozuldu"   then Ticket.where(status: "solved").order(solved_at: :desc)
    when "kapandi"   then Ticket.where(status: "closed").order(closed_at: :desc).limit(50)
    else Ticket.active.by_deadline
    end
  end
end
