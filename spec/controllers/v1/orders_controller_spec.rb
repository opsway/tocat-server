require 'rails_helper'

RSpec.describe V1::OrdersController, :type => :controller do
  render_views
  describe "GET 'index' " do
    it "returns a successful 200 response" do
      binding.pry
      get :index, format: :json
      expect(response).to be_success
    end
    it "return a vaid JSON" do
      get :index, formta: :json
      binding.pry
      expect("['Foo', 'Bar', 'Baz']").to have_json(['Foo', 'Bar', 'Baz'])

    end
  end
end
