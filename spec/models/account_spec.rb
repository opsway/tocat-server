require 'rails_helper'

RSpec.describe Account, :type => :model do
  it { should belong_to(:accountable) }
  it { should have_many(:transactions) }
  it { should validate_presence_of(:accountable_id) }
  it { should validate_presence_of(:accountable_type) }



  it "should create balance account" do
    account = build(:account)
    account.account_type = 'balance'
    account.should be_valid
  end

  it "should create payment account" do
    account = build(:account)
    account.account_type = 'payment'
    account.should be_valid
  end

  it "should not create record with wrong type" do
    account = build(:account)
    account.account_type = 'wrong'
    account.valid?
    account.errors.should have_key(:account_type)
  end

  it "should normalize account type" do
    account = build(:account)
    account.account_type = 'PayMenT'
    account.save
    account.reload
    account.account_type.should eq('payment')
  end

  it "should fails if accounts contain more than 2 record for User or Team" do
    team = create(:team)
    team.accounts << create(:account, :account_type => "balance")
    team.accounts << create(:account, :account_type => "payment")
    third_account = team.accounts.new
    third_account.account_type = "payment"
    third_account.valid?.should eq(false)
  end
end
