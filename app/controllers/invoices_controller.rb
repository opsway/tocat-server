class InvoicesController < ApplicationController
  before_action :set_invoice, except: [:index, :create]

  def index
    @filterrific = initialize_filterrific(
    Invoice,
    params
    ) or return

    @invoices = @filterrific.find
    paginate json: @invoices, per_page: params[:limit]
  end

  def show
    render json: @invoice, serializer: InvoiceShowSerializer
  end

  def create
    @invoice = Invoice.new(invoice_params)
    if @invoice.save
      render json: @invoice, status: 201, serializer: InvoiceShowSerializer
    else
      render json: error_builder(@invoice), status: :unprocessable_entity
    end
  end

  def destroy
    if @invoice.destroy
      render json: {}, status: 200
    else
      render json: error_builder(@invoice, "order"), status: :unprocessable_entity
    end
  end

  def set_paid
    @invoice.paid = true
    if @invoice.save
      render json: {}, status: 200
    else
      render json: error_builder(@invoice), status: :unprocessable_entity
    end
  end

  def delete_paid
    @invoice.paid = false
    if @invoice.save
      render json: {}, status: 200
    else
      render json: error_builder(@invoice), status: :unprocessable_entity
    end
  end

  private

  def set_invoice
    if params[:invoice_id].present?
      @invoice = Invoice.find(params[:invoice_id])
    else
      @invoice = Invoice.find(params[:id])
    end
  end

  def invoice_params
    params.permit(:external_id,
    :client)
  end
end
