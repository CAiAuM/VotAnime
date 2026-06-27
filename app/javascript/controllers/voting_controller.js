import { Controller } from "@hotwired/stimulus"

// Cuida do popup de confirmação e da atualização dinâmica das barras/ranking.
export default class extends Controller {
  connect() {
    this.modal = document.getElementById("vote-modal")
    this.modalTitle = this.modal.querySelector("[data-modal-anime-title]")
    this.pendingCard = null

    // Delegação de eventos: cada botão "Votar" abre o popup.
    this.element.addEventListener("click", (event) => {
      const button = event.target.closest("[data-vote-button]")
      if (button) this.openModal(button.closest(".card"))
    })

    this.modal.querySelector("[data-modal-yes]").addEventListener("click", () => this.confirmVote())
    this.modal.querySelector("[data-modal-no]").addEventListener("click", () => this.closeModal())
    this.modal.addEventListener("click", (event) => {
      if (event.target === this.modal) this.closeModal()
    })
  }

  openModal(card) {
    this.pendingCard = card
    this.modalTitle.textContent = card.querySelector(".card__title").textContent.trim()
    this.modal.hidden = false
  }

  closeModal() {
    this.modal.hidden = true
    this.pendingCard = null
  }

  async confirmVote() {
    const card = this.pendingCard
    if (!card) return

    const id = card.dataset.animeId
    const button = card.querySelector("[data-vote-button]")
    button.disabled = true
    this.closeModal()

    try {
      const response = await fetch(`${this.element.dataset.voteBaseUrl}/${id}/vote.json`, {
        method: "POST",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
          "Accept": "application/json"
        }
      })

      if (!response.ok) throw new Error(`HTTP ${response.status}`)

      const data = await response.json()
      this.applyRanking(data)
    } catch (error) {
      console.error("Falha ao registrar voto:", error)
      alert("Não foi possível registrar seu voto. Tente novamente.")
    } finally {
      button.disabled = false
    }
  }

  // Atualiza barra, contagem e posição de cada card e reordena a grade.
  applyRanking(data) {
    data.ranking.forEach((entry) => {
      const card = document.getElementById(`anime-${entry.id}`)
      if (!card) return

      card.dataset.position = entry.position
      card.querySelector("[data-bar-fill]").style.width = `${entry.percentage}%`
      card.querySelector("[data-votes-count]").textContent = this.formatNumber(entry.votes_count)
      card.querySelector("[data-rank]").textContent = `#${entry.position}`
    })

    // Reordena os cards conforme a nova classificação.
    const ordered = [...this.element.querySelectorAll(".card")].sort(
      (a, b) => Number(a.dataset.position) - Number(b.dataset.position)
    )
    ordered.forEach((card) => this.element.appendChild(card))
  }

  formatNumber(value) {
    return Number(value).toLocaleString("pt-BR")
  }
}
