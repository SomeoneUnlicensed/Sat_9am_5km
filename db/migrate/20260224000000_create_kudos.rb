class CreateKudos < ActiveRecord::Migration[7.1]
  def change
    create_table :kudos do |t|
      t.references :athlete, null: false, foreign_key: true
      t.references :result, null: false, foreign_key: true
      t.timestamps
    end
    add_index :kudos, [:athlete_id, :result_id], unique: true
  end
end
