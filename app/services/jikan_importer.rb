require "net/http"
require "openssl"
require "json"

# Busca os melhores animes na API pública Jikan (MyAnimeList) e persiste no banco.
# A API é gratuita e não exige chave: https://docs.api.jikan.moe/
#
# Como a página inicial classifica do 1º ao 100º lugar, buscamos animes
# suficientes (lançados nos últimos 20 anos) para preencher essa lista.
class JikanImporter
  BASE_URL = "https://api.jikan.moe/v4/top/anime".freeze
  YEARS_WINDOW = 20
  PER_PAGE = 25
  MAX_PAGES = 12 # margem de segurança para coletar ~100 animes válidos

  def self.call(...) = new(...).call

  def initialize(limit: Anime::RANKING_LIMIT, logger: nil)
    @limit = limit
    @logger = logger
    @min_year = Time.current.year - YEARS_WINDOW
  end

  # Retorna o array de hashes importados (também útil para gerar o seed).
  def call
    collected = []

    (1..MAX_PAGES).each do |page|
      break if collected.size >= @limit

      entries = fetch_page(page)
      break if entries.empty?

      entries.each do |raw|
        anime = normalize(raw)
        next unless anime && anime[:year] && anime[:year] >= @min_year

        collected << anime unless collected.any? { |a| a[:mal_id] == anime[:mal_id] }
      end

      log "Página #{page}: #{collected.size}/#{@limit} animes coletados"
      sleep 1 # respeita o rate limit da Jikan
    end

    persist(collected.first(@limit))
  end

  private

  def fetch_page(page)
    uri = URI("#{BASE_URL}?page=#{page}&limit=#{PER_PAGE}")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    # Usa o store de CAs padrão do sistema (evita erro de CRL em alguns OpenSSL).
    store = OpenSSL::X509::Store.new
    store.set_default_paths
    http.cert_store = store

    response = http.get(uri.request_uri)

    unless response.is_a?(Net::HTTPSuccess)
      log "Falha na página #{page}: HTTP #{response.code}"
      return []
    end

    JSON.parse(response.body).fetch("data", [])
  rescue StandardError => e
    log "Erro ao buscar página #{page}: #{e.message}"
    []
  end

  def normalize(raw)
    {
      mal_id: raw["mal_id"],
      title: raw["title_english"].presence || raw["title"],
      synopsis: raw["synopsis"].to_s.strip,
      image_url: raw.dig("images", "jpg", "large_image_url") || raw.dig("images", "jpg", "image_url"),
      year: raw["year"] || raw.dig("aired", "prop", "from", "year")
    }
  end

  def persist(records)
    records.each do |attrs|
      anime = Anime.find_or_initialize_by(mal_id: attrs[:mal_id])
      anime.assign_attributes(attrs.except(:mal_id))
      anime.save!
    end
    log "Importação concluída: #{records.size} animes salvos."
    records
  end

  def log(message)
    @logger&.puts(message)
  end
end
