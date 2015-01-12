require 'rails_helper'

RSpec.describe Team, :type => :model do
  context "validations" do

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:balance_account_id) }
    it { should validate_presence_of(:gross_profit_account) }
    it { should have_many(:orders) }
    it { should have_many(:users) }
    it { should have_many(:accounts) }

  end
end
