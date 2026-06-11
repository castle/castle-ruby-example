# frozen_string_literal: true

RSpec.describe CastleReporting, type: :controller do
  controller(ApplicationController) do
    skip_before_action :authenticate_user!

    def index
      record_castle_result(
        endpoint: 'risk',
        payload: { request_token: 'a' * 100, user: { id: '1' } },
        response: response_fixture
      )
      persist_castle_results
      redirect_to '/'
    end

    private

    def response_fixture
      {
        policy: { action: 'allow' },
        risk: 0.4,
        signals: { unreachable_email: {}, multiple_accounts_per_device: {} },
        # A large field that must not be persisted to the cookie session.
        device: { fingerprint: 'z' * 6_000 }
      }
    end
  end

  before { routes.draw { get 'index' => 'anonymous#index' } }

  describe 'persisting results across a redirect' do
    before { get :index }

    it 'keeps the verdict and risk score' do
      expect(flash[:castle_results].first['response']).to include(
        'policy' => { 'action' => 'allow' }, 'risk' => 0.4
      )
    end

    it 'reduces signals to their names' do
      expect(flash[:castle_results].first['response']['signals'])
        .to eq(%w[unreachable_email multiple_accounts_per_device])
    end

    it 'drops heavy fields such as device' do
      expect(flash[:castle_results].first['response']).not_to have_key('device')
    end

    it 'truncates the request token in the echoed payload' do
      expect(flash[:castle_results].first['payload']['request_token']).to end_with('…')
    end

    it 'stays within the cookie-session budget' do
      expect(flash[:castle_results].to_json.bytesize).to be <= CastleReporting::MAX_FLASHED_TOTAL_BYTES
    end
  end

  context 'when even the compacted results exceed the budget' do
    controller(ApplicationController) do
      skip_before_action :authenticate_user!

      def index
        record_castle_result(
          endpoint: 'risk',
          payload: {},
          response: { signals: (1..600).to_h { |i| ["signal_number_#{i}", {}] } }
        )
        persist_castle_results
        redirect_to '/'
      end
    end

    before do
      routes.draw { get 'index' => 'anonymous#index' }
      get :index
    end

    it 'drops the response body entirely' do
      expect(flash[:castle_results].first).not_to have_key('response')
    end

    it 'still records the endpoint' do
      expect(flash[:castle_results].first['endpoint']).to eq('risk')
    end
  end
end
