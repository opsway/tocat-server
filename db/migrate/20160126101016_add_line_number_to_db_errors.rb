class AddLineNumberToDbErrors < ActiveRecord::Migration
  def change
    add_column :db_errors, :line_number, :integer
  end
end
