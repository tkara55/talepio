module ApplicationHelper
  STATUS_LABELS = {
    "new" => "Yeni", "open" => "Açık", "pending" => "Beklemede",
    "solved" => "Çözüldü", "closed" => "Kapandı"
  }.freeze

  PRIORITY_LABELS = {
    "urgent" => "Acil", "high" => "Yüksek", "normal" => "Normal", "low" => "Düşük"
  }.freeze

  SLA_LABELS = {
    met: "Zamanında yanıtlandı", missed: "Geç yanıtlandı", on_track: "Süre var",
    at_risk: "Riskte", breached: "İhlal", none: "Yanıtsız kapandı"
  }.freeze

  def status_badge(status)
    tag.span(STATUS_LABELS.fetch(status), class: "badge status-#{status}")
  end

  def priority_badge(priority)
    tag.span(PRIORITY_LABELS.fetch(priority), class: "badge priority-#{priority}")
  end

  def priority_options
    Ticket::PRIORITIES.map do |p|
      [ "#{PRIORITY_LABELS[p]} (ilk yanıt: #{duration_label(SlaPolicy.target_for(p))})", p ]
    end
  end

  def duration_label(duration)
    minutes = (duration.to_i / 60.0).round
    return "#{minutes} dk" if minutes < 60

    hours, rest = minutes.divmod(60)
    rest.zero? ? "#{hours} sa" : "#{hours} sa #{rest} dk"
  end

  # Canlı geri sayım: sunucu durumu çizer, Stimulus her saniye günceller.
  def sla_chip(ticket, now)
    state = ticket.sla_state(now)
    if %i[on_track at_risk breached].include?(state)
      tag.span(class: "sla sla-#{state}", data: {
        controller: "countdown",
        countdown_deadline_value: ticket.first_response_due_at.iso8601,
        countdown_warning_value: SlaPolicy.warning_window(ticket.priority).to_i
      }) do
        tag.span(SLA_LABELS[state], data: { countdown_target: "label" }) +
          tag.span(countdown_text(ticket.seconds_remaining(now)), class: "sla-time", data: { countdown_target: "time" })
      end
    else
      tag.span(SLA_LABELS[state], class: "sla sla-#{state}")
    end
  end

  def countdown_text(seconds)
    sign = seconds.negative? ? "+" : ""
    total = seconds.abs
    h, rem = total.divmod(3600)
    m, s = rem.divmod(60)
    h.positive? ? format("%s%d:%02d:%02d", sign, h, m, s) : format("%s%02d:%02d", sign, m, s)
  end

  def time_label(time)
    return "—" unless time

    l(time, format: "%d %b %H:%M:%S")
  end
end
