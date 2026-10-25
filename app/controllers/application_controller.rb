class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_agent

  private

  def current_agent
    @current_agent ||= Agent.find_by(id: session[:agent_id]) if session[:agent_id]
  end

  def require_agent
    redirect_to new_session_path, alert: "Önce temsilci olarak giriş yapın." unless current_agent
  end

  # Radar her temsilci isteğinde de taranır; panel 30 sn'de bir yenilendiği için
  # biri kuyruğa bakarken gecikme en fazla 30 saniyedir.
  def sweep_sla_radar
    SlaRadar.sweep!
  end
end
