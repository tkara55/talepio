class AssignmentsController < ApplicationController
  before_action :require_agent

  def update
    ticket = Ticket.find(params[:ticket_id])
    agent = params[:assignee_id].present? ? Agent.find(params[:assignee_id]) : nil
    ticket.update!(assignee: agent)
    redirect_to ticket_path(ticket), notice: agent ? "#{agent.name} temsilcisine atandı." : "Atama kaldırıldı."
  end
end
