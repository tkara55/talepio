require "test_helper"

# Kullanıcı acısı: Zendesk'te SLA uyarıları saatlik otomasyonlara bağlı.
# Radar uyarıyı riskin başladığı dakikada üretmeli ve atanmamış talebi atamalı.
class SlaRadarTest < ActiveSupport::TestCase
  setup do
    @opened = Time.zone.local(2026, 10, 26, 9, 0, 0)
    @busy = create_agent(name: "Mert Kaya", email: "mert@talepio.test")
    @free = create_agent(name: "Zeynep Demir", email: "zeynep@talepio.test")
    travel_to(@opened - 1.hour) { create_ticket(assignee: @busy) }
  end

  test "15 dk SLA'lı talepte uyarı 10. dakikada, ihlal 15. dakikada kaydedilir" do
    ticket = travel_to(@opened) { create_ticket(priority: "urgent") }

    travel_to(@opened + 9.minutes) { SlaRadar.sweep! }
    assert_empty ticket.sla_events

    warned_at = @opened + 10.minutes + 30.seconds
    travel_to(warned_at) do
      result = SlaRadar.sweep!
      assert_equal 1, result.warnings
    end
    warning = ticket.sla_events.find_by!(kind: "warning")
    assert_equal warned_at, warning.created_at
    assert_equal 5, warning.minutes_remaining

    travel_to(@opened + 15.minutes + 20.seconds) { assert_equal 1, SlaRadar.sweep!.breaches }
    assert_equal 0, ticket.sla_events.find_by!(kind: "breach").minutes_remaining
  end

  test "aynı uyarı tekrar tekrar üretilmez" do
    ticket = travel_to(@opened) { create_ticket(priority: "urgent") }

    travel_to(@opened + 11.minutes) { SlaRadar.sweep! }
    travel_to(@opened + 12.minutes) { assert_equal 0, SlaRadar.sweep!.warnings }
    assert_equal 1, ticket.sla_events.where(kind: "warning").count
  end

  test "riskteki atanmamış talep işi en az olan temsilciye atanır" do
    ticket = travel_to(@opened) { create_ticket(priority: "urgent") }

    travel_to(@opened + 11.minutes) { SlaRadar.sweep! }

    assert_equal @free, ticket.reload.assignee
    assert_match "Zeynep Demir", ticket.sla_events.first.note
  end

  test "yanıtlanmış talep için uyarı üretilmez" do
    ticket = travel_to(@opened) { create_ticket(priority: "urgent") }
    travel_to(@opened + 2.minutes) { ticket.reply_as_agent!(@busy, "Bakıyorum.") }

    travel_to(@opened + 30.minutes) { SlaRadar.sweep! }
    assert_empty ticket.sla_events
  end

  test "radar 4 günü dolan çözülmüş talepleri de kapatır" do
    ticket = travel_to(@opened) { create_ticket }
    travel_to(@opened + 5.minutes) { ticket.reply_as_agent!(@busy, "Tamam.", status: "solved") }

    travel_to(@opened + 5.minutes + 4.days) { assert_equal 1, SlaRadar.sweep!.closed }
    assert_equal "closed", ticket.reload.status
  end
end
