module V1
  class OrdersController < ApplicationController
    before_action :set_order, except: [:index, :create]#, only: [:show, :edit, :update, :destroy]

    def index
      @orders = Order.all
      render json: @orders
    end

    def show
      render json: @order, serializer: OrderShowSerializer
    end

    def edit
    end

    def create
      @order = Order.new(order_params)
      save_and_render
    end

    def update
      if @order.update(order_params)
        render json: @order, serializer: OrderShowSerializer
      else
        render json: @order.errors, status: :unprocessable_entity
      end
    end

    def destroy
      @order.destroy
      render nothing: true, status: 204
    end

    def set_invoice
      @order.invoice = Invoice.find(params[:invoice_id])
      save_and_render
    end

    def delete_invoice
      @order.invoice_id = nil
      save_and_render
    end

    def set_paid
      @order.paid = true
      save_and_render
    end

    def set_unpaid
      @order.paid = false
      save_and_render
    end

    def suborders
      @suborders = @order.sub_orders.all
      render json: @suborders
    end

    def create_suborder
      render nothing: true, status: 204  #TODO waiting for commentary from Andriy
    end

    private

      def save_and_render
        if @order.save
          render json: @order, serializer: OrderShowSerializer
        else
          render json: @order.errors, status: :unprocessable_entity
        end
      end
      def set_order
        @order = Order.find(params[:id])
      end

      def order_params
        params.require(:order).permit(:name,
                                      :description,
                                      :team_id,
                                      :invoiced_budget,
                                      :allocatable_budget,
                                      :invoice_id)

      end
  end
end
