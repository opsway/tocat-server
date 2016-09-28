class TransactionsController < ApplicationController
  before_action :set_transaction, except: [:index]

  def index
    transactions = Transaction.includes(:account).search_for(params[:search])
    if params[:user].present?
      account_name = Account.find(params[:user]).name
      account_ids = Account.where(name: account_name).pluck :id
      transactions = transactions.where(account_id: account_ids)
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
