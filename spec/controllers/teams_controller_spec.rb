require 'rails_helper'

RSpec.describe TeamsController, type: :controller do
  describe '/team ' do
    before(:each) do
      create_list(:team, 5)
      get :index, format: :json
      @body = JSON.parse(response.body)
    end

    it 'returns a successful 200 response' do
      expect(response).to be_success
    end

    it 'return valid names' do
      db_names = Team.all.map(&:name)
      names = @body.map { |m| m['name'] }
      expect(names).to match_array(db_names)
    end

    it 'should check JSON schema' do
      expect(response).to match_response_schema_to_list('teams')
    end
  end

  describe '/team/:id' do
    before(:each) do
      team = create(:team)
      get :show, id: team.id, format: :json
      @body = JSON.parse(response.body)
    end

    it 'returns a successful 200 response' do
      expect(response).to be_success
    end

    it 'should check JSON schema' do
      expect(response).to match_response_schema('team')
    end
  end
end
