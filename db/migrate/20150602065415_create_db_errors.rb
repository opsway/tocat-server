class CreateDbErrors < ActiveRecord::Migration
  def change
    create_table :db_errors do |t|
      t.text :alert, null: false
      t.boolean :checked, default: false, null: false
      t.datetime :last_run
      t.timestamps null: false
    end
    drop_table :selfcheckreports if table_exists? :selfcheckreports
  end
end
