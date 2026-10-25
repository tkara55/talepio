# Müşterinin talep açtığı ve takip ettiği portal.
class RequestsController < ApplicationController
  def new
    @ticket = Ticket.new(priority: "normal")
  end

  def create
    @ticket = Ticket.new(request_params)
    if @ticket.save
      redirect_to request_path(@ticket.token), notice: "Talebiniz alındı. Bu sayfanın bağlantısını saklayın."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @ticket = Ticket.find_by!(token: params[:token])
  end

  private

  def request_params
    params.expect(ticket: %i[requester_name requester_email subject priority description])
  end
end
