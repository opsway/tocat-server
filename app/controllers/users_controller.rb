class UsersController < ApplicationController
  before_action :set_user, except: [:index, :create, :me]
  before_action :check_user, except: [:index, :create, :destroy, :show, :me]

  def index
    if params[:anyuser].present?
      @articles = User.search_for(params[:search]).order('users.active desc, users.name asc')
    else
      @articles = User.search_for(params[:search]).order('users.name asc').all_active
    end
    if params[:tocat_role].present?
      @roles = TocatRole.all.select{|r| r.allowed_to? params[:tocat_role] }
      @articles = @articles.joins(:tocat_role).where('tocat_roles.id in (?)', @roles.map(&:id))
    end

    if params[:limit].present? || params[:page].present? || params[:anyuser].present?
      return paginate json: @articles, per_page: params[:limit]
    else
      render json: @articles
    end
  end
  def me
    @user = User.current_user
    render json: @user, serializer: UserShowSerializer
  end
  def show
    render json: @user, serializer: UserShowSerializer
  end
  
  def correction
      Transaction.create!(comment: params[:comment].to_s.truncate(254),
                          total: params[:total],
                          account: @user.balance_account,
                          user_id: @user.id)
  end

  def add_payment
    if @user.add_payment(params[:comment], params[:total])
      render json: {}, status: 201
    else
      render json: error_builder(@user), status: :unprocessable_entity
    end
  end
  
  def salary_checkin
      Transaction.create!(comment: params[:comment].to_s.truncate(254),
                          total: params[:total],
                          account: @user.payroll_account,
                          user_id: @user.id)
      Transaction.create!(comment: params[:comment].to_s.truncate(254),
                          total: 0 - params[:total].to_f,
                          account: @user.balance_account,
                          user_id: @user.id)
      return render json: {}, status: 200
  end
  

  def set_role
    user = User.find(params[:user_id])
    role = TocatRole.find(params[:role])
    user.tocat_user_role.destroy if user.tocat_user_role.present?
    record = TocatUserRole.new(user: user, tocat_role:role, creator_id: User.current_user.id)
    if record.save
      render json: {}, status: 200
    else
      render json: {}, status: 406
    end
  end

  def create
    @user = User.new(user_params)
    if @user.save
      @user.create_activity :create,
                             parameters: user_params,
                             owner: User.current_user
      render json: @user, serializer: UserShowSerializer, status: 201
    else
      render json: error_builder(@user), status: 406
    end
  end

  def destroy
    params.permit!
    @user.create_activity :destroy,
      parameters: params,
      owner: User.current_user
    if @user.active
      @user.update_column(:active,false)
    else
      @user.update_column(:active,true)
    end
    render json: @user, serializer: UserShowSerializer, status: 200
  end

  def update
    user_attr = {}
    user_attr['name'] = @user.name
    user_attr['login'] = @user.login
    user_attr['team'] = @user.team.to_s
    user_attr['daily_rate'] = @user.daily_rate.to_s
    user_attr['role'] = @user.role.to_s
    if @user.update(user_params)
      @user.create_activity :update,
                             parameters: {changes: HashDiff.diff(user_attr, user_params)},
                             owner: User.current_user
      render json: @user, serializer: UserShowSerializer, status: 200
    else
      render json: error_builder(@user), status: 406
    end
  end

  private

  def set_user
    begin
      if params[:user_id].present?
        @user = User.find(params[:user_id])
      else
        @user = User.find(params[:id])
      end
    rescue ActiveRecord::RecordNotFound
      return render json: {}, status: 404
    end
  end

  def check_user
    unless @user.active?
      return render json: {errors: ['User is inactive']}, status: 422
    end
  end

  def user_params
    output = params.require(:user).permit(:name,
                                          :login,
                                          :daily_rate,
                                          :team_id,
                                          :email,
                                          :coach,
                                          :can_pay_withdraw_invoices,
                                          :role_id
                                          )
    if params[:user].try(:[],:team).present?
      output.merge!({ team_id: params[:user]['team']})
    end
    if params[:user].try(:[],:role).present? && params[:actions] != 'update'
      output.merge!({ role_id: params[:user].try(:[], :role)})
    end
    output
  end
end
