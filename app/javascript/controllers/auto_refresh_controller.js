import { Controller } from "@hotwired/stimulus"

// Kuyruğu belirli aralıklarla yeniler; her yenilemede sunucu SLA radarını tarar.
// Turbo morph sayesinde kaydırma konumu ve açık formlar korunur.
export default class extends Controller {
  static values = { seconds: { type: Number, default: 30 } }

  connect() {
    this.timer = setInterval(() => {
      if (document.visibilityState === "visible") Turbo.visit(window.location.href, { action: "replace" })
    }, this.secondsValue * 1000)
  }

  disconnect() {
    clearInterval(this.timer)
  }
}
