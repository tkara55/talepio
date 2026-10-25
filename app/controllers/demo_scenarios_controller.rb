# Sunumda saatlerce beklemeden zaman kurallarını göstermek için geçmiş tarihli
# örnek talepler üretir. Kuralların kendisi değişmez; sadece talebin açılış anı geriye alınır.
class DemoScenariosController < ApplicationController
  before_action :require_agent

  SCENARIOS = {
    "riskte" => "11 dakika önce açılmış acil talep (SLA 15 dk, son 5 dk riskte)",
    "ihlal"  => "20 dakika önce açılmış acil talep (SLA aşıldı)",
    "kapanacak" => "4 gün 1 saat önce çözülmüş talep (otomatik kapanır)"
  }.freeze

  def create
    ticket =
      case params[:id]
      when "riskte" then build(opened: 11.minutes.ago, subject: "Ödeme sayfası 500 hatası veriyor")
      when "ihlal"  then build(opened: 20.minutes.ago, subject: "Tüm kullanıcılar oturumdan atılıyor")
      when "kapanacak"
        build(opened: 5.days.ago, subject: "Fatura PDF'i indirilemiyor", priority: "normal").tap do |t|
          t.reply_as_agent!(current_agent, "Düzeltildi, tekrar dener misiniz?", status: "solved", at: 4.days.ago - 1.hour)
        end
      else raise ActiveRecord::RecordNotFound
      end

    # Kuyruk açılırken radar taradığı için "kapanacak" talep orada kapanmış görünür.
    redirect_to tickets_path(view: params[:id] == "kapanacak" ? "kapandi" : "aktif"),
                notice: "Demo talebi oluşturuldu: ##{ticket.id}"
  end

  private

  def build(opened:, subject:, priority: "urgent")
    Ticket.create!(
      subject: subject,
      description: "Demo senaryosu: #{subject}.",
      requester_name: "Demo Müşteri",
      requester_email: "demo@ornek.test",
      priority: priority,
      created_at: opened,
      updated_at: opened
    )
  end
end
