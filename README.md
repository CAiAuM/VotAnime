# VotAnime 🏆

Aplicação web para votar no **melhor anime dos últimos 20 anos**.

A página inicial mostra um card para cada anime com a imagem de capa, o nome, a
sinopse e uma barra de votos (de `0` a `9.999.999`). Ao clicar em **Votar**, um
popup pede confirmação; ao confirmar, o voto é contabilizado, a barra é
atualizada dinamicamente e a classificação (do **1º ao 100º lugar**) é
reordenada na hora.

Feito com **Ruby on Rails 8** + **ActiveRecord**, seguindo as convenções do Rails.

## Como funciona

- **Modelo `Anime`** (`app/models/anime.rb`): guarda `title`, `synopsis`,
  `image_url`, `year`, `mal_id` e o contador `votes_count`. Tem a lógica do
  ranking (`scope :ranked`), do incremento atômico de voto (`vote!`) e do
  percentual da barra (`vote_percentage`).
- **Dados dos animes**: são buscados na API pública e gratuita
  [Jikan (MyAnimeList)](https://docs.api.jikan.moe/) pelo serviço
  `app/services/jikan_importer.rb`. Os dados são salvos no banco **e** em
  `db/animes.json` (snapshot versionado), para que o app possa ser populado em
  produção sem depender da API.
- **Votação dinâmica**: o controller `Stimulus`
  (`app/javascript/controllers/voting_controller.js`) abre o popup de
  confirmação e, ao confirmar, faz um `POST` em `/animes/:id/vote.json`. O
  backend devolve a classificação atualizada e o front reordena os cards e as
  barras sem recarregar a página.

## Rodando localmente

Requisitos: Ruby 3.3+, SQLite.

```bash
bin/setup                 # instala dependências e prepara o banco
bin/rails db:seed         # popula os animes a partir de db/animes.json
bin/rails server          # http://localhost:3000
```

Para rebuscar os dados direto da API Jikan (atualiza o banco e o snapshot):

```bash
bin/rails animes:import
```

## Deploy no Fly.io

O projeto já vem com `Dockerfile` (gerado pelo Rails 8) e `fly.toml` prontos.
O banco SQLite fica em um volume persistente, e o `bin/docker-entrypoint`
prepara e popula o banco automaticamente na primeira subida.

1. Instale o [flyctl](https://fly.io/docs/flyctl/install/) e faça login:
   ```bash
   fly auth login
   ```
2. Crie o app (o nome em `fly.toml` precisa ser único globalmente — ajuste se
   necessário, ex.: `votanime-seunome`):
   ```bash
   fly apps create votanime
   ```
3. Crie o volume do banco na mesma região do `fly.toml` (`gru` = São Paulo):
   ```bash
   fly volumes create votanime_data --region gru --size 1
   ```
4. Configure a chave mestra do Rails como secret (o conteúdo de
   `config/master.key`, que **não** vai para o Git):
   ```bash
   fly secrets set RAILS_MASTER_KEY=$(cat config/master.key)
   ```
5. Faça o deploy:
   ```bash
   fly deploy
   ```
6. Abra o site:
   ```bash
   fly open
   ```

Pronto — o site fica acessível publicamente pela URL `https://<app>.fly.dev`.

## Licença

MIT.
