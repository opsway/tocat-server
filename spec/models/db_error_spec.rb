require 'rails_helper'

RSpec.describe DbError, :type => :model do

  it 'should find by boolean value' do
   expect(DbError.boolean_find(:test, '=', false)).to eq({:conditions=>"db_errors.test = 0"})
  end

  it 'should store new alerts' do
    count = DbError.count
    DbError.store('Test message')
    expect(DbError.count).to eq(count + 1)
  end

  it 'should return alert id if this alert already exists' do
    first_record = DbError.create(alert:'Test message')
    count = DbError.count
    second_record = DbError.store('Test message')
    expect(DbError.count).to eq(count)
    expect(second_record).to eq(first_record.id)
  end

end
