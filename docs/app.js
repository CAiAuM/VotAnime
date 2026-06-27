// VotAnime — versão estática (GitHub Pages).
// Os animes vêm de animes.js (window.ANIMES, snapshot da API Jikan) e os votos
// são contabilizados no navegador via localStorage.
(function () {
  "use strict";

  const MAX_VOTES = 9999999;            // teto da barra (0 a 9.999.999)
  const STORAGE_KEY = "votanime_votes"; // { mal_id: quantidade_de_votos }

  const grid = document.getElementById("grid");
  const modal = document.getElementById("vote-modal");
  const modalTitle = modal.querySelector("[data-modal-anime-title]");
  let pendingMalId = null;

  // --- Persistência dos votos (por navegador) ---
  function loadVotes() {
    try {
      return JSON.parse(localStorage.getItem(STORAGE_KEY)) || {};
    } catch (e) {
      return {};
    }
  }

  function saveVotes(votes) {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(votes));
  }

  function votesFor(malId) {
    return loadVotes()[malId] || 0;
  }

  function addVote(malId) {
    const votes = loadVotes();
    const current = votes[malId] || 0;
    if (current >= MAX_VOTES) return current;
    votes[malId] = current + 1;
    saveVotes(votes);
    return votes[malId];
  }

  // --- Helpers ---
  function formatNumber(value) {
    return Number(value).toLocaleString("pt-BR");
  }

  function percentage(count) {
    if (!count) return 0;
    return Math.round((count / MAX_VOTES) * 100 * 10000) / 10000;
  }

  // Lista de animes ordenada do mais votado para o menos votado.
  function ranked() {
    return window.ANIMES
      .map((anime) => ({ ...anime, votes: votesFor(anime.mal_id) }))
      .sort((a, b) => b.votes - a.votes || a.title.localeCompare(b.title));
  }

  // --- Renderização ---
  function cardHTML(anime, position) {
    const year = anime.year ? ` <span class="card__year">(${anime.year})</span>` : "";
    const synopsis = anime.synopsis && anime.synopsis.trim() ? anime.synopsis : "Sinopse indisponível.";
    return `
      <article class="card" id="anime-${anime.mal_id}" data-mal-id="${anime.mal_id}">
        <div class="card__image" style="background-image: url('${anime.image_url}');">
          <span class="card__rank" data-rank>#${position}</span>
        </div>
        <div class="card__body">
          <h2 class="card__title">${anime.title}${year}</h2>
          <p class="card__synopsis">${synopsis}</p>
          <button type="button" class="card__vote-btn" data-vote-button>Votar</button>
          <div class="bar" title="Votos">
            <div class="bar__fill" data-bar-fill style="width: ${percentage(anime.votes)}%;"></div>
            <span class="bar__label">
              <span data-votes-count>${formatNumber(anime.votes)}</span>
              / ${formatNumber(MAX_VOTES)} votos
            </span>
          </div>
        </div>
      </article>`;
  }

  function render() {
    const list = ranked();
    grid.innerHTML = list.map((anime, i) => cardHTML(anime, i + 1)).join("");
  }

  // Atualiza barras/contagens e reordena os cards após um voto, sem recriar tudo.
  function applyRanking() {
    const list = ranked();
    list.forEach((anime, index) => {
      const card = document.getElementById(`anime-${anime.mal_id}`);
      if (!card) return;
      card.querySelector("[data-bar-fill]").style.width = `${percentage(anime.votes)}%`;
      card.querySelector("[data-votes-count]").textContent = formatNumber(anime.votes);
      card.querySelector("[data-rank]").textContent = `#${index + 1}`;
      card.dataset.position = index + 1;
    });
    [...grid.querySelectorAll(".card")]
      .sort((a, b) => Number(a.dataset.position) - Number(b.dataset.position))
      .forEach((card) => grid.appendChild(card));
  }

  // --- Modal de confirmação ---
  function openModal(card) {
    pendingMalId = card.dataset.malId;
    modalTitle.textContent = card.querySelector(".card__title").textContent.trim();
    modal.hidden = false;
  }

  function closeModal() {
    modal.hidden = true;
    pendingMalId = null;
  }

  function confirmVote() {
    if (pendingMalId == null) return;
    addVote(pendingMalId);
    closeModal();
    applyRanking();
  }

  // --- Eventos ---
  grid.addEventListener("click", (event) => {
    const button = event.target.closest("[data-vote-button]");
    if (button) openModal(button.closest(".card"));
  });

  modal.querySelector("[data-modal-yes]").addEventListener("click", confirmVote);
  modal.querySelector("[data-modal-no]").addEventListener("click", closeModal);
  modal.addEventListener("click", (event) => {
    if (event.target === modal) closeModal();
  });

  document.querySelector("[data-reset]").addEventListener("click", () => {
    if (confirm("Zerar todos os votos guardados neste navegador?")) {
      localStorage.removeItem(STORAGE_KEY);
      render();
    }
  });

  render();
})();
