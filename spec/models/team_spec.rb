require 'rails_helper'

RSpec.describe Team, :type => :model do
  context "validations" do

    it { should validate_presence_of(:name) }
    it { should have_many(:orders) }
    it { should have_many(:users) }
    it { should have_many(:accounts) }

    it "should create two accounts after team creation" do
      team = create(:team)
      expect(team.accounts.length).to eq 2
    end

    it "should destroy team accounts if team was deleted" do
      team = create(:team)
      team_id = team.id
      team.destroy
      accounts = Account.where(:accountable_id => team_id)
      expect(accounts).to eq []
    end

  end
end
