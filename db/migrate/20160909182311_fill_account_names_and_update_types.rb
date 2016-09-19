class FillAccountNamesAndUpdateTypes < ActiveRecord::Migration
  def change
    Account.where(account_type: "payment").update_all(account_type: "payroll")
    Account.all.each do |a|
      a.name = "#{a.accountable.name} #{a.account_type}"
    end
  end
end
