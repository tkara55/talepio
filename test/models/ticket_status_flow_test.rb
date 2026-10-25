require "test_helper"

# Durum akışı: new > open > pending > solved > closed
class TicketStatusFlowTest < ActiveSupport::TestCase
  setup do
    @agent = create_agent
    @ticket = create_ticket
  end

  test "yeni talep 'new' durumunda ve gizli bir takip bağlantısıyla açılır" do
    assert_equal "new", @ticket.status
    assert @ticket.token.present?
  end

  test "temsilcinin ilk yanıtı talebi new > open yapar ve temsilciye atar" do
    @ticket.reply_as_agent!(@agent, "Bakıyorum.")

    assert_equal "open", @ticket.reload.status
    assert_equal @agent, @ticket.assignee
    assert_not_nil @ticket.first_responded_at
  end

  test "tam akış: new > open > pending > open > solved > closed" do
    @ticket.reply_as_agent!(@agent, "Bakıyorum.")
    assert_equal "open", @ticket.status

    @ticket.reply_as_agent!(@agent, "Ekran görüntüsü gönderir misiniz?", status: "pending")
    assert_equal "pending", @ticket.status

    @ticket.reply_as_requester!("Ekledim.")
    assert_equal "open", @ticket.status

    @ticket.reply_as_agent!(@agent, "Düzelttik.", status: "solved")
    assert_equal "solved", @ticket.status
    assert_not_nil @ticket.solved_at

    @ticket.transition_to!("closed")
    assert_equal "closed", @ticket.reload.status
    assert_not_nil @ticket.closed_at
  end

  test "müşteri çözülmüş talebe yazarsa talep yeniden açılır" do
    @ticket.reply_as_agent!(@agent, "Düzelttik.", status: "solved")
    @ticket.reply_as_requester!("Hâlâ olmuyor.")

    assert_equal "open", @ticket.reload.status
    assert_nil @ticket.solved_at
  end

  test "geçersiz geçişler reddedilir" do
    assert_raises(Ticket::InvalidTransition) { @ticket.transition_to!("closed") }

    @ticket.transition_to!("solved")
    @ticket.transition_to!("closed")
    assert_raises(Ticket::InvalidTransition) { @ticket.transition_to!("open") }
    assert_raises(Ticket::InvalidTransition) { @ticket.reply_as_requester!("Merhaba?") }
    assert_raises(Ticket::InvalidTransition) { @ticket.reply_as_agent!(@agent, "Merhaba?") }
  end

  test "geçiş tablosu her durum için tanımlı" do
    assert_equal Ticket::STATUSES.sort, Ticket::TRANSITIONS.keys.sort
    Ticket::TRANSITIONS.each_value { |targets| assert (targets - Ticket::STATUSES).empty? }
  end
end
