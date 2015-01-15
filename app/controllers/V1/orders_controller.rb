module V1
  class OrdersController < ApplicationController
    before_action :set_order, :except => [:index, :create]#, only: [:show, :edit, :update, :destroy]

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
      respond_to do |format|
        if @order.save
          format.json { render json: @order, serializer: OrderShowSerializer }
        else
          format.json { render json: @order.errors, status: :unprocessable_entity }
        end
      end
    end

    def update
      respond_to do |format|
        if @order.update(order_params)
          format.json { head :no_content }
        else
          format.json { render json: @order.errors, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      @order.destroy
      respond_to do |format|
        format.json { head :no_content }
      end
    end

    def set_invoice
      @order.invoice = Invoice.find(params[:invoice_id])
      respond_to do |format|
        if @order.save
          format.json { render json: @order, serializer: OrderShowSerializer }
        else
          format.json { render json: @order.errors, status: :unprocessable_entity }
        end
      end
    end

    def delete_invoice
      @order.invoice_id = nil
      respond_to do |format|
        if @order.save
          format.json { render json: @order, serializer: OrderShowSerializer }
        else
          format.json { render json: @order.errors, status: :unprocessable_entity }
        end
      end
    end

    def set_paid
      @order.paid = true
      respond_to do |format|
        if @order.save
          format.json { render json: @order, serializer: OrderShowSerializer }
        else
          format.json { render json: @order.errors, status: :unprocessable_entity }
        end
      end
    end

    def set_unpaid
      @order.paid = false
      respond_to do |format|
        if @order.save
          format.json { render json: @order, serializer: OrderShowSerializer }
        else
          format.json { render json: @order.errors, status: :unprocessable_entity }
        end
      end
    end

    def suborders
      @suborders = @order.sub_orders.all
      render json: @suborders
    end

    def create_suborder
      format.json { head :no_content } #TODO waiting for commentary from Andriy
    end

    private
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
