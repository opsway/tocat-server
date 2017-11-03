require 'rails_helper'

RSpec.describe TimelogsController, :type => :controller do
  describe '/timelogs' do
    get :index, format: :json

    it 'returns a successful 200 response' do
      expect(response).to be_success
    end


  end

end
