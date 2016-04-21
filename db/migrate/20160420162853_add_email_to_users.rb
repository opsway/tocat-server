class AddEmailToUsers < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.string :email, null: true, default: nil
    end

    reversible do |change|
      change.up do
        execute <<-SQL
          UPDATE users SET email = CONCAT(login, '@opsway.com')
        SQL
      end
    end
  end
end
