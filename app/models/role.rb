class Role < ActiveRecord::Base
  validates :name, presence: true

  before_save :normalize_name
  has_many :users

  private

  def normalize_name
    if self.name.split(" ").length >= 2
      self.name = self.name.titleize
    else
      self.name = self.name.capitalize
    end
  end
end
