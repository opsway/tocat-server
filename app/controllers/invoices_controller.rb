class InvoicesController < ApplicationController
  before_action :set_invoice, except: [:index, :create]

  def index
    @articles = Invoice.search_for(params[:search]).order(sort)
    if params[:sort].present?
      params[:sort].split.each do |o|
        if o == 'total:asc' || o == 'total:desc'
          @articles = Invoice.sorted_by_total(o.split(':').second)
        end
      end
    end
    paginate json: @articles, per_page: params[:limit]
  end

  def show
    render json: @invoice, serializer: InvoiceShowSerializer
  end

  def create
    @invoice = Invoice.new(invoice_params)
    if @invoice.save
      @invoice.create_activity :created, parameters: invoice_params, owner: User.current_user
      render json: @invoice, status: 201, serializer: InvoiceShowSerializer
    else
      render json: error_builder(@invoice), status: :unprocessable_entity
    end
  end

  def destroy
    if @invoice.destroy
      PublicActivity::Activity.create! owner: @invoice, key: 'invoice.destroy'
      render json: {}, status: 200
    else
      render json: error_builder(@invoice), status: :unprocessable_entity
    end
  end

  def set_paid
    if @invoice.update_attributes(paid: true)
      @invoice.create_activity :paid_update,
                               parameters: { old: !@invoice.paid,
                                             new: @invoice.paid },
                               owner: User.current_user
      render json: {}, status: 200
    else
      render json: error_builder(@invoice), status: :unprocessable_entity
    end
  end

  def delete_paid
    if @invoice.update_attributes(paid: false)
      @invoice.create_activity :paid_update,
                               parameters: { old: !@invoice.paid,
                                             new: @invoice.paid },
                               owner: User.current_user
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
    params.permit(:external_id)
  end
end
