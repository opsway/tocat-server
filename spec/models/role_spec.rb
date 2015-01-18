require 'rails_helper'

RSpec.describe Role, type: :model do
  it { should validate_presence_of(:name) }
  it { should have_many(:users) }
  it 'should titelize name' do
    role = build(:role)
    role.name = 'MaNaGeR'
    role.save
    role.reload
    role.name.should eq('Manager')
    role.name = 'Mana ger'
    role.save
    role.reload
    role.name.should eq('Mana Ger')
  end
end
