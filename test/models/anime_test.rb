require "test_helper"

class AnimeTest < ActiveSupport::TestCase
  test "vote! incrementa o contador de forma atômica" do
    anime = Anime.create!(mal_id: 1, title: "Teste", votes_count: 0)
    assert_equal 1, anime.vote!
    assert_equal 1, anime.reload.votes_count
  end

  test "vote! respeita o teto da barra" do
    anime = Anime.create!(mal_id: 2, title: "Teto", votes_count: Anime::MAX_VOTES)
    assert_equal Anime::MAX_VOTES, anime.vote!
  end

  test "vote_percentage é proporcional ao máximo" do
    anime = Anime.new(votes_count: Anime::MAX_VOTES)
    assert_equal 100.0, anime.vote_percentage
    anime.votes_count = 0
    assert_equal 0.0, anime.vote_percentage
  end

  test "ranked ordena do mais votado para o menos votado" do
    Anime.create!(mal_id: 10, title: "B", votes_count: 5)
    Anime.create!(mal_id: 11, title: "A", votes_count: 50)
    assert_equal "A", Anime.ranked.first.title
  end

  test "mal_id é obrigatório e único" do
    Anime.create!(mal_id: 20, title: "Único")
    dup = Anime.new(mal_id: 20, title: "Repetido")
    assert_not dup.valid?
  end
end
