# Kullanıcı acısının çözümü (bkz. README §5). İlham alınan üründe SLA koşulları yalnızca saatte bir çalışan
# otomasyonlarda kullanılabiliyor: uyarı ihlalden bir saat önce ya da sonra gelebiliyor.
# SlaRadar her dakika (ve panel her yenilendiğinde) tarar:
#   - "riskte"ye giren talep için tam o dakikada uyarı kaydı açar,
#   - atanmamışsa işi en az olan temsilciye atar,
#   - ihlal anını dakika hassasiyetinde kaydeder,
#   - çözülmüş talepleri 4 gün sonra kapatır.
class SlaRadar
  Result = Struct.new(:warnings, :breaches, :closed, keyword_init: true)

  def self.sweep!(now = Time.current)
    new(now).sweep!
  end

  def initialize(now)
    @now = now
  end

  def sweep!
    result = Result.new(warnings: 0, breaches: 0, closed: 0)

    Ticket.awaiting_first_response.find_each do |ticket|
      case ticket.sla_state(@now)
      when :at_risk
        result.warnings += 1 if record!(ticket, "warning")
      when :breached
        result.breaches += 1 if record!(ticket, "breach")
      end
    end

    result.closed = Ticket.auto_close_solved!(@now)
    result
  end

  private

  def record!(ticket, kind)
    return false if ticket.sla_events.exists?(kind: kind)

    note = nil
    if ticket.assignee.nil? && (agent = Agent.least_loaded)
      ticket.update!(assignee: agent)
      note = "Atanmamıştı, #{agent.name} temsilcisine otomatik atandı"
    end

    ticket.sla_events.create!(
      kind: kind,
      minutes_remaining: (ticket.seconds_remaining(@now) / 60.0).ceil,
      note: note,
      created_at: @now
    )
    true
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    false
  end
end
