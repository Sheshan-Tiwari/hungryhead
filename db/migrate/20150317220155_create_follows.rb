class CreateFollows < ActiveRecord::Migration
  disable_ddl_transaction!
  def up
    create_table :follows do |t|
      t.references :followable, polymorphic: true, null: false
      t.references :follower, polymorphic: true, null: false
      t.timestamps null: false
    end
    add_index :follows, [:follower_id, :followable_id, :followable_type], unique: true, algorithm: :concurrently
  end

  def down
    drop_table :follows
  end
end
