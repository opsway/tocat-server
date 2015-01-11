require 'rails_helper'

RSpec.describe Invoice, :type => :model do
  it {should validate_presence_of(:client)}
  it {should validate_presence_of(:external_id)}
  it {should validate_presence_of(:paid)}
  it {should belong_to(:order)}
end
