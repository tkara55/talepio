class RepliesController < ApplicationController
  before_action :require_agent

  def create
    ticket = Ticket.find(params[:ticket_id])
    body = params.dig(:reply, :body).to_s.strip

    if body.blank?
      redirect_to ticket_path(ticket), alert: "Yanıt boş olamaz."
    else
      ticket.reply_as_agent!(current_agent, body, status: params[:status])
      redirect_to ticket_path(ticket), notice: "Yanıt gönderildi."
    end
  rescue Ticket::InvalidTransition => e
    redirect_to ticket_path(ticket), alert: e.message
  end
end
