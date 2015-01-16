module V1
  class TransactionsController < ApplicationController
    before_action :set_transaction, except: [:index]

    def index
      @transactions = Transaction.all
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
end
