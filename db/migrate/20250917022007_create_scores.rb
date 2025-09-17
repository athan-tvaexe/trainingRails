class CreateScores < ActiveRecord::Migration[8.0]
  def change
    create_table :scores do |t|
      t.string :user
      t.integer :points

      t.timestamps
    end
  end
end
