class Team < ActiveRecord::Base
  include Accounts
  include PublicActivity::Common
  belongs_to :parent, foreign_key: :parent_id, class_name: Team
  has_many :children, foreign_key: :parent_id, class_name: Team
  validates :name, :parent_id, :default_commission, presence: true
  has_many :orders
  has_many :users
  has_many :roles, :through => :users, source: :role
  def manager
    users.joins(:role).where('roles.name = ?', 'Manager').where(active: true).first
  end
  def couch(team = self)
    couch = team.users.where(active: true, real_money: true).first #in order (list)
    unless couch
      couch = couch(team.parent) 
    end
    couch
  end
  
  def all_children
    func = lambda do |team|
      res = []
      res << team.child_ids
    end
    all = [self.id]
    all << child_ids
    all << children.where.not(id: self.id).map {|c| func.call c }
    all.flatten
  end

  def self.central_office
    #Team.where(name: 'Central Office').first
    Team.where('parent_id = id').first
  end
  def change_manager(manager_id)o.allocatable_budget
    current_manager = manager
    current_manager.update(role: Role.find_by(name: 'Developer')) if current_manager
    new_manager = User.find(manager_id) if manager_id > 0
    new_manager.update(role: Role.find_by(name: 'Manager')) if new_manager
  end
end
