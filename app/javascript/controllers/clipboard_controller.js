import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source"]

  copy() {
    const text = this.sourceTarget.value
    navigator.clipboard.writeText(text).then(() => {
      this.element.dispatchEvent(new CustomEvent("brief:clipboard", { bubbles: true }))
    })
  }
}
