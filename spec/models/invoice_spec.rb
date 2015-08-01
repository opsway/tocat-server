require 'rails_helper'

RSpec.describe Invoice, type: :model do
  it { should have_many(:orders) }
  let(:invoice) { create(:invoice, paid: false)}

  it 'should count total of invoice orders' do
    create_list(:order, 10, invoice: invoice, invoiced_budget: 5, allocatable_budget: 1)
    total = Order.where(invoice: invoice).sum(:invoiced_budget)
    expect(invoice.total).to eq(total)
  end
end
