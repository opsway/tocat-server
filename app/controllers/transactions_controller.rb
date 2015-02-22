class TransactionsController < ApplicationController
  before_action :set_transaction, except: [:index]

  def index
    @filterrific = initialize_filterrific(
    Transaction,
    params
    ) or return

    @transactions = @filterrific.find
    paginate json: @transactions, per_page: params[:limit]
  end

  def show
    render json: @transaction, serializer: TransactionShowSerializer
  end

  private

  def set_transaction
    @transaction = Transaction.find(params[:id])
  end
end
