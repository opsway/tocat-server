class AddParentIdToTeam < ActiveRecord::Migration
  def change
    add_column :teams, :parent_id, :integer, index: true, null: false
    Team.reset_column_information
    Team.update_all(parent_id: Team.where(name: 'Central Office').first.try(:id))
  end
end
