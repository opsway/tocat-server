class AddTransactionalMicropaymentToSettings < ActiveRecord::Migration
  def up
    Setting.find_or_create_by(name: 'transactional_micropayment', value: '10')
  end
  def down
    Setting.where(name: 'transactional_micropayment').delete_all
  end
end
