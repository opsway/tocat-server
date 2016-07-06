class AclController < ApplicationController
  def acl
    render json: User.current_user.tocat_role.try(:permissions).to_json
  end
end
