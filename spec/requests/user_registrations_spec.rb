require 'rails_helper'

RSpec.describe 'User Registrations', type: :request do
  # テスト前にユーザーを作成
  let!(:user) { create(:user) }

  describe 'POST /api/v1/auth' do
    it 'successfully registers a new user and sends a confirmation email' do
      post '/api/v1/auth',
            params: { name: 'First User',
                      email: 'first@example.com',
                      role: :admin,
                      password: 'password',
                      password_confirmation: 'password',
                      confirm_success_url: 'http://localhost:5173/confirmed' }
      expect(response).to have_http_status(:success)
      expect(ActionMailer::Base.deliveries.last.to).to include('first@example.com')
    end

    it 'returns an error when passwords do not match' do
      post '/api/v1/auth',
            params: { name: 'Second User',
                      email: 'second@example.com',
                      role: :admin,
                      password: 'password',
                      password_confirmation: 'wrong_password',
                      confirm_success_url: 'http://localhost:5173/confirmed' }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns an error when email is already taken' do
      post '/api/v1/auth',
            params: { name: 'Third User',
                      email: 'test@example.com',
                      role: :admin,
                      password: 'password',
                      password_confirmation: 'password',
                      confirm_success_url: 'http://localhost:5173/confirmed' }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns an error when email is invalid' do
      post '/api/v1/auth',
            params: { name: 'Fourth User',
                      email: 'invalid_email',
                      role: :admin,
                      password: 'password',
                      password_confirmation: 'password',
                      confirm_success_url: 'http://localhost:5173/confirmed' }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
