class TransitionsController < ApplicationController
  before_action :require_agent

  def create
    ticket = Ticket.find(params[:ticket_id])
    ticket.transition_to!(params[:status])
    redirect_to ticket_path(ticket), notice: "Durum güncellendi."
  rescue Ticket::InvalidTransition => e
    redirect_to ticket_path(ticket), alert: e.message
  end
end
