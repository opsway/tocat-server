class HistoryOfChangeDailyRatesController < ApplicationController

  def index
    @rates = HistoryOfChangeDailyRate
    paginate json: @rates, per_page: params[:limit]
  end
end
