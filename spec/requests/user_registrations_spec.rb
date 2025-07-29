require 'rails_helper'

RSpec.describe 'User Registrations', type: :request do
  # テスト前にユーザーを作成
  let!(:confirmed_user) { create(:confirmed_user) }

  describe 'POST /api/v1/auth' do
    it 'successfully registers a new user and sends a confirmation email' do
      post '/api/v1/auth',
            params: { name: 'First User',
                      email: 'first@example.com',
                      password: 'password',
                      password_confirmation: 'password'
                    }
      mail = ActionMailer::Base.deliveries.last
      expect(response).to have_http_status(:success)
      expect(mail.to).to include('first@example.com')
      expect(mail.subject).to eq('メールアドレス確認メール')
      MAIL_BODY = [
        "アカウント登録の確認",
        "First Userさん、こんにちは！",
        "アカウント登録を完了するため、",
        "以下のリンクをクリックしてください。URLは24時間有効です。",
        "メールアドレスを確認する"
      ]
      MAIL_BODY.each do |line|
        expect(mail.body.encoded).to include(line)
      end
    end

    it 'returns an error when passwords do not match' do
      post '/api/v1/auth',
            params: { name: 'Second User',
                      email: 'second@example.com',
                      password: 'password',
                      password_confirmation: 'wrong_password'
                    }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns an error when email is already taken' do
      post '/api/v1/auth',
            params: { name: 'Third User',
                      email: confirmed_user.email, 
                      password: 'password',
                      password_confirmation: 'password'
                    }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns an error when email is invalid' do
      post '/api/v1/auth',
            params: { name: 'Fourth User',
                      email: 'invalid_email',
                      password: 'password',
                      password_confirmation: 'password'
                    }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
