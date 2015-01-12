require 'rails_helper'

RSpec.describe Transaction, :type => :model do
  it { should belong_to(:user) }
  it { should belong_to(:account) }
  it { should validate_presence_of(:account_id) }
  it { should validate_presence_of(:user_id) }
  it { should validate_presence_of(:total) }
  it "should fails if total lower than or equals zero" do
    t = build(:transaction)
    t.total = 0
    t.valid?
    t.errors.should have_key(:total)
    t.total = -10
    t.valid?
    t.errors.should have_key(:total)
  end

end
