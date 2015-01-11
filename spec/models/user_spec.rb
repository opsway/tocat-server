require 'rails_helper'

RSpec.describe User, :type => :model do
  it {should validate_presence_of(:name)}
  it {should validate_presence_of(:login)}
  it {should validate_presence_of(:balance_account)}
  it {should validate_presence_of(:income_account)}
  it {should validate_presence_of(:team_id)}
  it {should validate_presence_of(:daily_rate)}
  it {should validate_presence_of(:role)}
  it {should belong_to(:team)}
  it {should belong_to(:role)}
  it {should have_many(:transactions)}
  it "should normalize name and login" do
    user = build(:user)
    user.login = "teUsR"
    user.name = "TEST USER"
    user.save
    user.reload
    user.name.should eq("Test User")
    user.login.should eq("teusr")
  end
end
