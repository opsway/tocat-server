class Ability
  include CanCan::Ability

  def initialize(user)
    if user.role_id == 2
      can :manage, :all
    else
      can :read, :all
    end
  end

end
