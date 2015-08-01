require 'rails_helper'

RSpec.describe Transaction, type: :model do
  it { should belong_to(:user) }
  it { should belong_to(:account) }
  it { should validate_presence_of(:account_id) }
  it { should validate_presence_of(:total) }

  it "should return transaction for given user" do
    user = create(:user)
    second_user = create(:user)
    create_list(:transaction, 10, user: user, account: user.accounts.first)
    create_list(:transaction, 20, user: second_user, account: second_user.accounts.first)
    expect(Transaction.user(user.id).collect(&:account_id).uniq).to eq([user.accounts.first.id])
  end

  it "should return transaction for given team" do
    team = create(:team)
    second_team = create(:team )
    create_list(:transaction, 10, account: team.accounts.first)
    create_list(:transaction, 20, account: second_team.accounts.first)
    expect(Transaction.team(team.id).collect(&:account_id).uniq).to eq([team.accounts.first.id])
  end

  it 'should fail if transaction can be deleted or destroyed' do
    transaction = create(:transaction)
    expect { Transaction.destroy_all }.to raise_error
    expect { Transaction.delete_all }.to raise_error
    expect { Transaction.first.destroy }.to raise_error
    expect { Transaction.first.delete }.to raise_error
    expect { Transaction.destroy_all! }.to raise_error
    expect { Transaction.delete_all! }.to raise_error
    expect { Transaction.first.destroy! }.to raise_error
    expect { Transaction.first.delete! }.to raise_error
  end

end
