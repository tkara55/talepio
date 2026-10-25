import { Controller } from "@hotwired/stimulus"

// İlk yanıt SLA'sı için saniye saniye geri sayım.
// Durum sınırı (riskte / ihlal) geçildiğinde rozet sayfa yenilenmeden değişir.
export default class extends Controller {
  static targets = ["label", "time"]
  static values = { deadline: String, warning: Number }

  connect() {
    this.deadline = new Date(this.deadlineValue).getTime()
    this.tick()
    this.timer = setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  tick() {
    const seconds = Math.round((this.deadline - Date.now()) / 1000)
    let state = "on_track", label = "Süre var"
    if (seconds <= 0) { state = "breached"; label = "İhlal" }
    else if (seconds <= this.warningValue) { state = "at_risk"; label = "Riskte" }

    this.element.className = `sla sla-${state}`
    this.labelTarget.textContent = label
    this.timeTarget.textContent = this.format(seconds)
  }

  format(seconds) {
    const sign = seconds < 0 ? "+" : ""
    let total = Math.abs(seconds)
    const h = Math.floor(total / 3600)
    total %= 3600
    const m = Math.floor(total / 60)
    const s = total % 60
    const pad = (n) => String(n).padStart(2, "0")
    return h > 0 ? `${sign}${h}:${pad(m)}:${pad(s)}` : `${sign}${pad(m)}:${pad(s)}`
  }
}
