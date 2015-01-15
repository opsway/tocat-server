require 'rails_helper'

RSpec.describe User, :type => :model do
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:login) }
  it { should validate_presence_of(:team_id) }
  it { should validate_presence_of(:daily_rate) }
  it { should validate_presence_of(:role_id) }
  it { should belong_to(:team) }
  it { should belong_to(:role) }
  it { should have_many(:transactions) }
  it { should have_many(:accounts) }
  it { should have_many(:tasks) }
  it "should normalize name and login" do
    user = build(:user)
    user.login = "teUsR"
    user.name = "TEST USER"
    user.save
    user.reload
    user.name.should eq("Test User")
    user.login.should eq("teusr")
  end

  it "should create two accounts after user creation" do
    user = create(:user)
    expect(user.accounts.length).to eq 2
  end

  it "should destroy user accounts if user was deleted" do
    user = create(:user)
    user_id = user.id
    user.destroy
    accounts = Account.where(:accountable_id => user_id)
    expect(accounts).to eq []
  end
end
