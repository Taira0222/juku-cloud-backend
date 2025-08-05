require "rails_helper"

RSpec.describe "UserConfirmations", type: :request do
  let!(:unconfirmed_user) { create(:user, :unconfirmed) }

  describe "GET /api/v1/auth/confirmation" do
    it "redirect confirm success url (account_confirmation_success=true) for unconfirmed user" do
      get '/api/v1/auth/confirmation', params: { confirmation_token: unconfirmed_user.confirmation_token }
      expect(response).to have_http_status(:redirect)
      expect(response.headers['Location']).to eq('http://localhost:5173/confirmed?account_confirmation_success=true')
    end

    it "redirect confirm success url (account_confirmation_success=false) for invalid token" do
      get '/api/v1/auth/confirmation', params: { confirmation_token: "invalid_token" }
      expect(response).to have_http_status(:redirect)
      expect(response.headers['Location']).to eq('http://localhost:5173/confirmed?account_confirmation_success=false')
    end

    it "redirect confirm success url (account_confirmation_success=false) if confirmation token is already expired" do
      unconfirmed_user.update(confirmation_sent_at: 3.days.ago)
      get '/api/v1/auth/confirmation', params: { confirmation_token: unconfirmed_user.confirmation_token }
      expect(response).to have_http_status(:redirect)
      expect(response.headers['Location']).to eq('http://localhost:5173/confirmed?account_confirmation_success=false')
    end

    it "redirect confirm success url (account_confirmation_success=false) for already confirmed user" do
      unconfirmed_user.update(confirmed_at: Time.current)
      get '/api/v1/auth/confirmation', params: { confirmation_token: unconfirmed_user.confirmation_token }
      expect(response).to have_http_status(:redirect)
      expect(response.headers['Location']).to eq('http://localhost:5173/confirmed?account_confirmation_success=false')
    end
  end
end
