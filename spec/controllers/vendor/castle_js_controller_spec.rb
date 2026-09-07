# frozen_string_literal: true

RSpec.describe Vendor::CastleJsController do
  describe 'GET #show' do
    it 'returns 404 for a missing file' do
      get :show, params: { filename: 'nope.js' }

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 when the path escapes the dist directory' do
      get :show, params: { filename: '../package.json' }

      expect(response).to have_http_status(:not_found)
    end

    it 'serves castle.browser.js from the npm install' do
      get :show, params: { filename: 'castle.browser.js' }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('application/javascript')
    end
  end
end
