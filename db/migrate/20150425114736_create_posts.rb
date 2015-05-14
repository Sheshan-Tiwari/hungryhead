class CreatePosts < ActiveRecord::Migration
  disable_ddl_transaction!
  def change
    create_table :posts do |t|

      t.string :title, null: false, default: ""
      t.text :body, null: false, default: ""

      t.string :slug, null: false, default: ""

      t.integer :status
      t.belongs_to :user, foreign_key: true, null: false

      t.timestamps null: false
    end
    add_index :posts, :status, algorithm: :concurrently
    add_index :posts, :user_id, algorithm: :concurrently
    add_index :posts, :slug, unique: true, algorithm: :concurrently
  end
end