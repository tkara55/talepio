require "test_helper"

# Aort dilimi uçtan uca, HTTP üzerinden: müşteri talep açar, temsilci yanıtlar ve çözer,
# müşteri yeniden açar, tekrar çözülür, 4 gün sonra radar kapatır.
class AortFlowTest < ActionDispatch::IntegrationTest
  setup do
    @agent = create_agent
  end

  test "talep gelir, atanır, yanıtlanır, çözülür, kapanır" do
    opened = Time.zone.local(2026, 10, 26, 9, 0, 0)
    travel_to opened

    post requests_path, params: { ticket: {
      requester_name: "Ayşe Şahin", requester_email: "ayse@ornek.test",
      subject: "Faturamda çift çekim var", priority: "high", description: "İki kez çekildi."
    } }
    ticket = Ticket.last
    assert_redirected_to request_path(ticket.token)
    follow_redirect!
    assert_select "h1", "Faturamda çift çekim var"
    assert_equal "new", ticket.status

    # Temsilci giriş yapar, kuyrukta talebi görür
    post session_path, params: { agent_id: @agent.id }
    get tickets_path
    assert_response :success
    assert_select "a", "Faturamda çift çekim var"

    # İlk yanıt 20. dakikada: SLA karşılanır, talep atanır ve beklemeye alınır
    travel 20.minutes
    post ticket_replies_path(ticket), params: { reply: { body: "Kontrol ediyorum, banka dekontu iletir misiniz?" }, status: "pending" }
    ticket.reload
    assert_equal "pending", ticket.status
    assert_equal @agent, ticket.assignee
    assert_equal :met, ticket.sla_state

    # Müşteri yanıtı talebi yeniden açar
    post request_reply_path(ticket.token), params: { reply: { body: "Dekont ekte." } }
    assert_equal "open", ticket.reload.status

    # Temsilci çözer
    post ticket_replies_path(ticket), params: { reply: { body: "İade başlatıldı." }, status: "solved" }
    assert_equal "solved", ticket.reload.status

    # 4 gün sonra kuyruk açıldığında radar talebi kapatır
    travel 4.days
    get tickets_path(view: "kapandi")
    assert_equal "closed", ticket.reload.status
    assert_select "td", /Faturamda çift çekim var/

    # Kapanmış talebe müşteri yazamaz
    post request_reply_path(ticket.token), params: { reply: { body: "Bir şey daha" } }
    assert_equal "closed", ticket.reload.status
    assert_equal "Kapanmış talebe yanıt yazılamaz", flash[:alert]
  ensure
    travel_back
  end

  test "geçersiz durum geçişi arayüzden de reddedilir" do
    ticket = create_ticket
    post session_path, params: { agent_id: @agent.id }

    post ticket_transitions_path(ticket), params: { status: "closed" }
    assert_redirected_to ticket_path(ticket)
    assert_equal "new → closed geçişi yapılamaz", flash[:alert]
    assert_equal "new", ticket.reload.status
  end

  test "giriş yapmamış kullanıcı kuyruğu göremez" do
    get tickets_path
    assert_redirected_to new_session_path
  end

  test "eksik bilgiyle talep açılamaz" do
    post requests_path, params: { ticket: { requester_name: "", requester_email: "x", subject: "", priority: "normal", description: "" } }
    assert_response :unprocessable_entity
    assert_equal 0, Ticket.count
  end

  test "demo senaryosu riskteki talebi kuyrukta radar uyarısıyla gösterir" do
    post session_path, params: { agent_id: @agent.id }
    post demo_scenarios_path(id: "riskte")
    follow_redirect!

    ticket = Ticket.last
    assert_equal :at_risk, ticket.sla_state
    assert ticket.sla_events.exists?(kind: "warning")
    assert_select ".event-warning", /Uyarı/
  end
end
