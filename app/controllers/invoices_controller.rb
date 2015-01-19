class InvoicesController < ApplicationController
  before_action :set_invoice, except: [:index, :create]

  def index
    @invoices = Invoice.all
    render json: @invoices
  end

  def show
    render json: @invoice, serializer: InvoiceShowSerializer
  end

  def create
    @invoice = Invoice.new(invoice_params)
    if @invoice.save
      render nothing: true, status: 201
    else
      render json: @invoice.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @invoice.destroy
    render nothing: true, status: 204
  end

  def set_paid
    @invoice.paid = true
    if @invoice.save
      render nothing: true, status: 202
    else
      render json: @invoice.errors, status: :unprocessable_entity
    end
  end

  def delete_paid
    @invoice.paid = false
    if @invoice.save
      render nothing: true, status: 202
    else
      render json: @invoice.errors, status: :unprocessable_entity
    end
  end

  private

  def set_invoice
    @invoice = invoice.find(params[:id])
  end

  def invoice_params
    params.permit(:external_id,
                  :client)
  end
end
