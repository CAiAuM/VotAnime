namespace :animes do
  DATA_FILE = Rails.root.join("db", "animes.json")

  desc "Importa os melhores animes dos últimos 20 anos da API Jikan e salva no banco e em db/animes.json"
  task import: :environment do
    records = JikanImporter.call(logger: $stdout)

    # Persiste uma cópia em JSON para o seed reproduzir os dados sem chamar a API.
    payload = Anime.ranked.map do |anime|
      anime.slice("mal_id", "title", "synopsis", "image_url", "year")
    end
    File.write(DATA_FILE, JSON.pretty_generate(payload))
    puts "Snapshot salvo em #{DATA_FILE} (#{payload.size} animes)."
  end

  desc "Popula o banco a partir de db/animes.json (sem chamar a API)"
  task load_snapshot: :environment do
    unless File.exist?(DATA_FILE)
      abort "Arquivo #{DATA_FILE} não encontrado. Rode 'bin/rails animes:import' primeiro."
    end

    data = JSON.parse(File.read(DATA_FILE))
    data.each do |attrs|
      anime = Anime.find_or_initialize_by(mal_id: attrs["mal_id"])
      anime.assign_attributes(attrs.except("mal_id"))
      anime.save!
    end
    puts "#{data.size} animes carregados de #{DATA_FILE}."
  end
end
