# Popula o banco com os animes. Em produção/deploy usamos o snapshot commitado
# (db/animes.json); se ele não existir, buscamos direto na API Jikan.
data_file = Rails.root.join("db", "animes.json")

if File.exist?(data_file)
  data = JSON.parse(File.read(data_file))
  data.each do |attrs|
    anime = Anime.find_or_initialize_by(mal_id: attrs["mal_id"])
    anime.assign_attributes(attrs.except("mal_id"))
    anime.save!
  end
  puts "Seed: #{data.size} animes carregados de db/animes.json."
else
  puts "Seed: db/animes.json não encontrado, buscando na API Jikan..."
  JikanImporter.call(logger: $stdout)
end
