class CreateTimesheets < ActiveRecord::Migration
  def change
    create_table :timesheets do |t|
      t.integer :sp_id, :null => false
      t.integer :user_id, :null => false
      t.datetime :start_timestamp, :null => false
      t.datetime :end_timestamp, :null => false
      t.integer :in_day, :null => false
      t.timestamps null: false
    end
  end
end
