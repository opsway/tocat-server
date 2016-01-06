class CreateStatusCheckTable < ActiveRecord::Migration
  def change
    create_table :status_checks do |t|
      t.datetime :start_run
      t.datetime :finish_run
    end
  end
end
