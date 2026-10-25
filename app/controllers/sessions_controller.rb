# Demo girişi: temsilci listeden seçilir (şifre yok, bkz. README "Yapamadıklarım").
class SessionsController < ApplicationController
  def new
    @agents = Agent.order(:name)
  end

  def create
    agent = Agent.find(params[:agent_id])
    session[:agent_id] = agent.id
    redirect_to tickets_path, notice: "#{agent.name} olarak giriş yapıldı."
  end

  def destroy
    session.delete(:agent_id)
    redirect_to root_path, notice: "Çıkış yapıldı."
  end
end
