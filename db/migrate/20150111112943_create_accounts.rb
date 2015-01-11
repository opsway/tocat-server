class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.string :account_type, :null => false #word "type" reserved by rails,
                                             #so, "account_type"
      t.timestamps
    end
  end
end
