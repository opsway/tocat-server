class CreateTasks < ActiveRecord::Migration
  def change
    create_table :tasks do |t|
      t.string :external_id
      t.integer :user_id
      t.boolean :accepted, :default => false
      t.boolean :paid, :default => false
      t.timestamps
    end
  end
end
