module Helpers
  def helpers_params(params)
    params['team'] = {'id' => params.delete('team_id')} if params['team_id'].present?
    params['role'] = {'id' => params.delete('role_id')} if params['role_id'].present?
    p params
    params
  end
end