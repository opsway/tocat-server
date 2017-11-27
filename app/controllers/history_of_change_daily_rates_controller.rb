class HistoryOfChangeDailyRatesController < ApplicationController

  def index
    @rates = HistoryOfChangeDailyRate.search_for(params[:search])
    paginate json: @rates, per_page: params[:limit]
  end
end
