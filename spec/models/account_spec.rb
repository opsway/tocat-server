require 'rails_helper'

RSpec.describe Account, :type => :model do
  it {should belong_to(:team)}
  it {should belong_to(:user)}

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
end
