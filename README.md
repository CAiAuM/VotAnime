# VotAnime 🏆

Aplicação web para votar no **melhor anime dos últimos 20 anos**.

A página inicial mostra um card para cada anime com a imagem de capa, o nome, a
sinopse e uma barra de votos (de `0` a `9.999.999`). Ao clicar em **Votar**, um
popup pede confirmação; ao confirmar, o voto é contabilizado, a barra é
atualizada dinamicamente e a classificação (do **1º ao 100º lugar**) é
reordenada na hora.

Feito com **Ruby on Rails 8** + **ActiveRecord** (SQLite), seguindo as convenções
do Rails. Há também uma **versão estática** publicada no GitHub Pages para
demonstração (veja abaixo).

🔗 **Demo online:** https://caiaum.github.io/VotAnime/

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

## Publicação no GitHub Pages (versão estática)

O GitHub Pages só serve conteúdo **estático** (HTML/CSS/JS) — ele **não roda
Rails**. Por isso, a pasta [`docs/`](docs/) contém uma versão estática do
VotAnime, publicada em https://caiaum.github.io/VotAnime/.

Essa versão:

- usa os mesmos dados de anime do snapshot `db/animes.json` (gerados em
  `docs/animes.js`);
- mostra os cards, a barra de votos, o botão **Votar** e o popup de confirmação;
- contabiliza os votos **no próprio navegador** (via `localStorage`) e reordena o
  ranking ao vivo. Como é client-side, os votos são locais a cada navegador e
  podem ser zerados pelo botão "Zerar votos" — é uma demonstração, não um placar
  global.

Para publicar: em **Settings > Pages** do repositório, selecione a branch `master`
e a pasta `/docs`. Para atualizar os dados, rode `bin/rails animes:import` e
regenere `docs/animes.js` a partir de `db/animes.json`.

> A aplicação Rails completa (com votos persistidos em banco) continua no
> repositório e roda localmente conforme a seção acima. O `Dockerfile` gerado
> pelo Rails 8 permite hospedá-la em plataformas que rodam containers.

## Licença

MIT.
