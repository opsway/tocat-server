require 'rails_helper'

RSpec.describe Account, type: :model do
  it { should belong_to(:accountable) }
  it { should have_many(:transactions) }
  it { should validate_presence_of(:accountable_id) }
  it { should validate_presence_of(:accountable_type) }

  it 'should create balance account' do
    account = build(:account)
    account.account_type = 'balance'
    account.should be_valid
  end

  it 'should create payment account' do
    account = build(:account)
    account.account_type = 'payment'
    account.should be_valid
  end

  it 'should not create record with wrong type' do
    account = build(:account)
    account.account_type = 'wrong'
    account.valid?
    account.errors.should have_key(:account_type)
  end

  it 'should normalize account type' do
    account = build(:account)
    account.account_type = 'PayMenT'
    account.save
    account.reload
    account.account_type.should eq('payment')
  end

  it 'should fails if accounts contain more than 2 record for User or Team' do
    team = create(:team)
    account_1 = build(:account, account_type: 'balance', accountable_type: 'Team', accountable_id: team.id)
    account_2 = build(:account, account_type: 'payment', accountable_type: 'Team', accountable_id: team.id)
    account_1.valid?
    account_2.valid?
    expect(account_1.errors).to have_key(:accountable)
    expect(account_2.errors).to have_key(:accountable)
  end

  it 'should return transactions total' do
    team = create(:team)
    create_list(:transaction, 10, total: 100, account: team.accounts.first)
    expect(team.accounts.first.balance).to eq(Transaction.where(account: team.accounts.first).sum(:total))
  end
end
