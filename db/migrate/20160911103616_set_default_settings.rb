class SetDefaultSettings < ActiveRecord::Migration
  def change
    User.find_each do |user|
      user.accounts.find_or_create_by account_type: 'money'
    end
    Team.find_each do |team|
      team.accounts.find_or_create_by account_type: 'money'
    end
    Account.where(name: nil).find_each do |a|
      Account.where(id: a.id).update_all(name: "#{a.accountable.name} #{a.account_type}")
    end


    account_names = ['Growth Fund','Finance Fund','Teams Fund','Dividends Fund']
    account_names.each do |name|
      Account.create(name: name, account_type: 'money', accountable_id: 0, accountable_type: '')
    end
    Team.central_office.accounts.where(account_type: 'money').update_all(name: 'Central Office')
    [{name: 'transactional_commission', value: 10},
     {name: 'external_payment_commission', value: 2},
     {name: 'finance_service_email', value: 'accountant@opsway.com'},
     {name: 'central_office_commission', value: 7},
     {name: 'growth_commission', value: 10},
     {name: 'finance_commission', value: 1},
     {name: 'teams_commission', value: 5},
     {name: 'dividends_commission', value: 5},
     {name: 'growth_fund_account_id', value: Account.find_by_name('Growth Fund').id},
     {name: 'finance_fund_account_id', value: Account.find_by_name('Finance Fund').id},
     {name: 'teams_fund_account_id', value: Account.find_by_name('Teams Fund').id},
     {name: 'central_office_account_id', value: Account.find_by_name('Central Office').id},
     {name: 'dividends_fund_account_id', value: Account.find_by_name('Dividends Fund').id},
    ].each do |s|
      Setting.find_or_create_by(s)
    end
  end
end
