class RequesterRepliesController < ApplicationController
  def create
    ticket = Ticket.find_by!(token: params[:request_token])
    body = params.dig(:reply, :body).to_s.strip

    if body.blank?
      redirect_to request_path(ticket.token), alert: "Mesaj boş olamaz."
    else
      ticket.reply_as_requester!(body)
      redirect_to request_path(ticket.token), notice: "Mesajınız iletildi."
    end
  rescue Ticket::InvalidTransition => e
    redirect_to request_path(ticket.token), alert: e.message
  end
end
