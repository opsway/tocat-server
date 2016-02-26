class Role < ActiveRecord::Base
  validates :name, presence: true

  before_save :normalize_name
  has_many :users
  has_many :teams, through: :users, source: :team
  scope :managers, ->{where name: 'Manager'}
  scope :developers, ->{where name: 'Developer'}

  def manager?
    name =~ /manager/i
  end

  private

  def normalize_name
    if self.name.split(' ').length >= 2
      self.name = self.name.titleize
    else
      self.name = self.name.capitalize
    end
  end
end
