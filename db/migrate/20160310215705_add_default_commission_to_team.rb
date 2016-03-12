class AddDefaultCommissionToTeam < ActiveRecord::Migration
  def change
    add_column :teams, :default_commission, :integer
  end
end
