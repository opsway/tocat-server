class TransactionsController < ApplicationController
  before_action :set_transaction, except: [:index, :create]

  def create
    @transaction = Transaction.new(transaction_params)
    if @transaction.save(context: :api)
      render json: @transaction, serializer: TransactionShowSerializer, status: 201
    else
      render json: error_builder(@transaction), status: :unprocessable_entity
    end
  end

  def index
    if params[:search].present?
      transactions = Transaction.includes(:account).search_for(params[:search])
    else
      transactions = Transaction.includes(:account).all
    end

    if params[:user].present?
      transactions = transactions.user(params[:user])
    elsif params[:team].present?
      transactions = transactions.team(params[:team])
    end

    @articles = transactions.order(sort)
    paginate json: @articles, per_page: params[:limit]
  end

  def show
    render json: @transaction, serializer: TransactionShowSerializer
  end

  private

  def set_transaction
    @transaction = Transaction.includes(account: :accountable).find(params[:id])
  end

  def transaction_params
    params.permit(:total, :comment).merge({account_id: params.try(:[], 'account').try(:[], 'id')})
  end
end
