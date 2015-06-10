# This migration comes from help (originally 20150608203817)
class CreateHelpArticles < ActiveRecord::Migration
  def change
    create_table :help_articles do |t|
      t.string :title
      t.text :body
      t.string :slug, null: false
      t.integer :category_id, index: true

      t.timestamps null: false
    end
    add_index :help_articles, :slug, unique: true
  end
end
