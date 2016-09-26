class TransactionsController < ApplicationController
  before_action :set_transaction, except: [:index]

  def index
    transactions = Transaction.includes(:account).search_for(params[:search])
    if params[:account].present?
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
end
