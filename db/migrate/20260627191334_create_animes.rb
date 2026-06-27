class CreateAnimes < ActiveRecord::Migration[8.0]
  def change
    create_table :animes do |t|
      t.integer :mal_id
      t.string :title
      t.text :synopsis
      t.string :image_url
      t.integer :year
      t.integer :votes_count, null: false, default: 0

      t.timestamps
    end
    add_index :animes, :mal_id, unique: true
    add_index :animes, :votes_count
  end
end
