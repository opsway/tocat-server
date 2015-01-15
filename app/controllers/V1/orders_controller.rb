module V1
  class OrdersController < ApplicationController
    before_action :set_order, :except => [:index, :create]#, only: [:show, :edit, :update, :destroy]

    # GET /orders
    # GET /orders.json
    def index
      @orders = Order.all
      render json: @orders
    end

    # GET /orders/1
    # GET /orders/1.json
    def show
      render json: @order, serializer: OrderShowSerializer
    end

    # GET /orders/1/edit
    def edit
    end

    # POST /orders
    # POST /orders.json
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

    # PATCH/PUT /orders/1
    # PATCH/PUT /orders/1.json
    def update
      respond_to do |format|
        if @order.update(order_params)
          format.json { head :no_content }
        else
          format.json { render json: @order.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /orders/1
    # DELETE /orders/1.json
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
      # Use callbacks to share common setup or constraints between actions.
      def set_order
        @order = Order.find(params[:id])
      end

      # Never trust parameters from the scary internet, only allow the white list through.
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
