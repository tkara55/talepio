require "test_helper"

# Zaman kuralları: ilk yanıt SLA'sı ve 4 gün sonra otomatik kapanış (travel_to ile).
class TicketTimeRulesTest < ActiveSupport::TestCase
  setup do
    @agent = create_agent
    @opened = Time.zone.local(2026, 10, 26, 9, 0, 0)
  end

  test "ilk yanıt son tarihi önceliğe göre hesaplanır" do
    travel_to @opened do
      assert_equal @opened + 15.minutes, create_ticket(priority: "urgent").first_response_due_at
      assert_equal @opened + 1.hour, create_ticket(priority: "high").first_response_due_at
      assert_equal @opened + 4.hours, create_ticket(priority: "normal").first_response_due_at
      assert_equal @opened + 8.hours, create_ticket(priority: "low").first_response_due_at
    end
  end

  test "acil talep: 10 dk'da süre var, 10:01'de riskte, 15:00'te ihlal" do
    ticket = travel_to(@opened) { create_ticket(priority: "urgent") }

    travel_to(@opened + 9.minutes + 59.seconds) { assert_equal :on_track, ticket.sla_state }
    travel_to(@opened + 10.minutes + 1.second) { assert_equal :at_risk, ticket.sla_state }
    travel_to(@opened + 14.minutes + 59.seconds) { assert_equal :at_risk, ticket.sla_state }
    travel_to(@opened + 15.minutes) { assert_equal :breached, ticket.sla_state }
  end

  test "normal talepte risk penceresi hedefin son %25'idir (son 1 saat)" do
    ticket = travel_to(@opened) { create_ticket(priority: "normal") }

    travel_to(@opened + 2.hours + 59.minutes) { assert_equal :on_track, ticket.sla_state }
    travel_to(@opened + 3.hours + 1.minute) { assert_equal :at_risk, ticket.sla_state }
  end

  test "zamanında yanıt :met, geç yanıt :missed olarak kalır" do
    on_time = travel_to(@opened) { create_ticket(priority: "high") }
    late = travel_to(@opened) { create_ticket(priority: "high") }

    travel_to(@opened + 30.minutes) { on_time.reply_as_agent!(@agent, "Buradayım.") }
    travel_to(@opened + 61.minutes) { late.reply_as_agent!(@agent, "Pardon, geciktik.") }

    travel_to(@opened + 1.day) do
      assert_equal :met, on_time.sla_state
      assert_equal :missed, late.sla_state
    end
  end

  test "çözülen talep tam 4 gün sonra otomatik kapanır, öncesinde kapanmaz" do
    ticket = travel_to(@opened) { create_ticket }
    travel_to(@opened + 1.hour) { ticket.reply_as_agent!(@agent, "Düzeldi.", status: "solved") }
    solved_at = @opened + 1.hour

    travel_to(solved_at + 4.days - 1.minute) do
      assert_equal 0, Ticket.auto_close_solved!
      assert_equal "solved", ticket.reload.status
    end

    travel_to(solved_at + 4.days) do
      assert_equal 1, Ticket.auto_close_solved!
      assert_equal "closed", ticket.reload.status
      assert_equal solved_at + 4.days, ticket.closed_at
    end
  end

  test "müşteri yazıp talebi yeniden açarsa otomatik kapanış sayacı sıfırlanır" do
    ticket = travel_to(@opened) { create_ticket }
    travel_to(@opened + 1.hour) { ticket.reply_as_agent!(@agent, "Düzeldi.", status: "solved") }
    travel_to(@opened + 3.days) { ticket.reply_as_requester!("Yine oldu.") }

    travel_to(@opened + 10.days) do
      assert_equal 0, Ticket.auto_close_solved!
      assert_equal "open", ticket.reload.status
    end
  end
end
