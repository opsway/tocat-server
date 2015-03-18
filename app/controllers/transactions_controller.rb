class TransactionsController < ApplicationController
  before_action :set_transaction, except: [:index]

  def index
    if params[:search].present?
      transactions = Transaction.search_for(params[:search])
    else
      transactions = Transaction.all
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
    @transaction = Transaction.find(params[:id])
  end
end
