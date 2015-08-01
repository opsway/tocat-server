require 'rails_helper'

RSpec.describe Task, type: :model do
  it { should validate_presence_of(:external_id).with_message("Missing external task ID") }
  it { should have_many(:orders).through(:task_orders) }
  it { should belong_to(:user) }
end
