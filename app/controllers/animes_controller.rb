class AnimesController < ApplicationController
  # A página inicial mostra a classificação (1º ao 100º lugar).
  def index
    @animes = Anime.ranking.to_a
  end

  # Contabiliza um voto e devolve o estado atualizado para a barra dinâmica.
  def vote
    anime = Anime.find(params[:id])
    anime.vote!

    respond_to do |format|
      format.json { render json: vote_response(anime) }
      format.html { redirect_to root_path }
    end
  end

  private

  # Após o voto a classificação muda, então devolvemos a lista de posições
  # atualizada para o front-end reordenar os cards e as barras.
  def vote_response(voted)
    ranking = Anime.ranking.to_a

    {
      voted_id: voted.id,
      max_votes: Anime::MAX_VOTES,
      ranking: ranking.map.with_index(1) do |anime, position|
        {
          id: anime.id,
          position: position,
          votes_count: anime.votes_count,
          percentage: anime.vote_percentage
        }
      end
    }
  end
end
