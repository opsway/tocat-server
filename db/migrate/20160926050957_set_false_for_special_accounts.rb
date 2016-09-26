class SetFalseForSpecialAccounts < ActiveRecord::Migration
 def change
    Account.update_all(pay_comission: true)
    Account.where(id: Setting.where("name like '%account_id'").pluck(:value).map(&:to_i)).update_all(pay_comission: false)
  end
end
