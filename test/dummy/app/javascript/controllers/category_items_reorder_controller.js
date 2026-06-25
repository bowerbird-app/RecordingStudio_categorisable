import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status"]
  static values = { url: String }

  connect() {
    this.handleReordered = this.handleReordered.bind(this)
    this.element.addEventListener("table:reordered", this.handleReordered)
  }

  disconnect() {
    this.element.removeEventListener("table:reordered", this.handleReordered)
  }

  async handleReordered() {
    if (!this.hasUrlValue) return

    const orderedRecordingIds = this.rowIds()
    this.setStatus("Saving order...")

    try {
      const response = await fetch(this.urlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": this.csrfToken()
        },
        credentials: "same-origin",
        body: JSON.stringify({ ordered_recording_ids: orderedRecordingIds })
      })

      const payload = await response.json()
      if (!response.ok || !payload.ok) {
        throw new Error(payload.error || "Could not save order.")
      }

      this.setStatus("Order saved.")
    } catch (error) {
      this.setStatus(error.message || "Could not save order.")
    }
  }

  rowIds() {
    return Array.from(this.element.querySelectorAll("tbody tr[data-id]"))
      .map((row) => row.dataset.id)
      .filter(Boolean)
  }

  csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content || ""
  }

  setStatus(message) {
    if (!this.hasStatusTarget) return
    this.statusTarget.textContent = message
  }
}
