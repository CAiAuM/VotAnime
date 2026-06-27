class Anime < ApplicationRecord
  # Valor máximo exibido pela barra de votos (0 a 9.999.999).
  MAX_VOTES = 9_999_999

  # Quantos colocados a classificação considera (1º ao 100º lugar).
  RANKING_LIMIT = 100

  validates :mal_id, presence: true, uniqueness: true
  validates :title, presence: true
  validates :votes_count, numericality: { greater_than_or_equal_to: 0 }

  # Ordenados do mais votado para o menos votado (desempate por título).
  scope :ranked, -> { order(votes_count: :desc, title: :asc) }

  # Top N usado para montar a classificação (1º ao 100º).
  scope :ranking, -> { ranked.limit(RANKING_LIMIT) }

  # Incremento atômico do contador de votos, respeitando o teto da barra.
  def vote!
    return votes_count if votes_count >= MAX_VOTES

    Anime.where(id: id).update_all("votes_count = votes_count + 1")
    reload.votes_count
  end

  # Percentual (0 a 100) que a barra deve ocupar para este anime.
  def vote_percentage
    return 0.0 if votes_count.zero?

    ((votes_count.to_f / MAX_VOTES) * 100).round(4)
  end
end
