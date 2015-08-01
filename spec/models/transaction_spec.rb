require 'rails_helper'

RSpec.describe Transaction, type: :model do
  it { should belong_to(:user) }
  it { should belong_to(:account) }
  it { should validate_presence_of(:account_id) }
  it { should validate_presence_of(:total) }
end
