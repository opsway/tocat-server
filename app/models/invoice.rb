class Invoice < ActiveRecord::Base
  validates_presence_of :client
  validates_presence_of :external_id
  validates_presence_of :paid
  belongs_to :order
end
