class CreateIdeas < ActiveRecord::Migration
  def change
    create_table :ideas do |t|
      t.integer :student_id, :null => false, index: true
      t.string :name
      t.string :slug, index: true, :unique => true
      t.string :high_concept_pitch, default: ""
      t.text :elevator_pitch, default: ""
      t.text :description, default: ""
      t.string :logo
      t.string :cover
      t.string :team, array: true, default: "{}"
      t.string :team_invites, array: true, default: "{}"
      t.string :feedbackers, array: true, default: "{}"
      t.string :investors, array: true, default: "{}"
      t.boolean :looking_for_team, index: true, default: false
      t.integer :school_id, index: true
      t.integer :status, index: true, default: 0
      t.integer :privacy, index: true, default: 0
      t.jsonb :settings, default: "{}"
      t.jsonb  :media, :default => "{}"
      t.jsonb :profile, default: "{}"
      t.jsonb :sections, default: "{}"
      t.jsonb :fund, default: "{}"
      t.string :cached_location_list
      t.string :cached_market_list
      t.string :cached_technology_list
      t.integer :feedbacks_count, default: 0
      t.integer :followers_count, default: 0
      t.integer :comments_count,default: 0
      t.integer :cached_votes_total, default: 0
      t.integer :idea_messages_count,  default: 0
      t.timestamps null: false
    end
    add_index :ideas, :profile, using: :gin
    add_index :ideas, :settings, using: :gin
    add_index :ideas, :fund, using: :gin
  end
end
