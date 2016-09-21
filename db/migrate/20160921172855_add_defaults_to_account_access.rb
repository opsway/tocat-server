class AddDefaultsToAccountAccess < ActiveRecord::Migration
  def change
    User.find_each do |u|
      Account.where(accountable_id: u.id, accountable_type: 'User').each do |a|
        AccountAccess.create(user: u, account: a, default: true)
      end
    end
  end
end
