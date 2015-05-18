class CreateSelfcheckreports < ActiveRecord::Migration
  def change
    create_table :selfcheckreports do |t|
      t.text :messages, null: false
      t.timestamps null: false
    end
  end
end
