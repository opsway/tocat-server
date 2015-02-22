class TransactionsController < ApplicationController
  before_action :set_transaction, except: [:index]

  def index
    if params[:user].present?
      @transactions = []
      Account.with_accountable(params[:user], 'user').each do |account|
        @transactions << account.transactions
      end
      @transactions.flatten!
    elsif params[:team].present?
      @transactions = []
      Account.with_accountable(params[:team], 'team').each do |account|
        @transactions << account.transactions
      end
      @transactions.flatten!
    else
      @transactions = Transaction.all
    end
    render json: @transactions
  end

  def show
    render json: @transaction, serializer: TransactionShowSerializer
  end

  private

  def set_transaction
    @transaction = Transaction.find(params[:id])
  end
end
