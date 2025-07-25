require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  # --TODO:: email変更 or パスワードリセットの画面を作成したらコメントアウトを解除する--
  # let!(:user) { create(:user) }
  describe "confirmation_instructions" do
    context "when a new user is created" do
      it "renders the confirmation instructions email" do
        token = Devise.token_generator.generate(User, :confirmation_token).first
        confirming_user = User.build(name: "Confirming User", email: "confirming@example.com")
        # optsパラメータにredirect_urlを指定
        opts = { redirect_url: "http://localhost:5173" }
        mail = UserMailer.confirmation_instructions(confirming_user, token, opts)

        expect(mail.subject).to eq("メールアドレスの確認をお願いします")
        expect(mail.to).to eq([ confirming_user.email ])
        expect(mail.from).to eq([ "no-reply@example.com" ])

        MAIL_BODY = [
          "アカウント登録の確認",
          "アカウント登録を完了するため、",
          "以下のリンクをクリックしてください。URLは24時間有効です。",
          "メールアドレスを確認する",
          "ボタンが動作しない場合は、以下のURLをブラウザにコピーしてアクセスしてください。",
          "localhost:5173/confirm?confirmation_token=#{token}"
        ]
        MAIL_BODY.each do |line|
          expect(mail.body.encoded).to include(line)
        end
      end
    end

    # --TODO:: email変更の画面を作成したらコメントアウトを解除する--
    # context "when a user requests a email reset" do
    #   it "renders the email reset instructions email" do
    #     token = Devise.token_generator.generate(User, :confirmation_token).first
    #     user.update(unconfirmed_email: 'new_email@example.com')
    #     # optsパラメータにredirect_urlを指定
    #     opts = { redirect_url: "http://localhost:5173" }
    #     mail = UserMailer.confirmation_instructions(user, token, opts)

    #     expect(mail.subject).to eq("新しいメールアドレスの確認をお願いします")
    #     expect(mail.to).to eq([user.unconfirmed_email])
    #     expect(mail.from).to eq(["no-reply@example.com"])

    #     MAIL_BODY = [
    #       "新しいメールアドレスの確認",
    #       "メールアドレスの変更を確認するため、",
    #       "以下のリンクをクリックしてください。URLは24時間有効です。",
    #       "localhost:5173/confirm?confirmation_token=#{token}"
    #     ]
    #     MAIL_BODY.each do |line|
    #       expect(mail.body.encoded).to include(line)
    #     end
    #   end
    # end
  end

  # --TODO:: パスワードリセットの画面を作成したらコメントアウトを解除する--

  # describe "reset_password_instructions" do
  #   it "renders the reset password instructions email" do
  #     token = Devise.token_generator.generate(User, :reset_password_token).first
  #     user.update(reset_password_sent_at: Time.current)
  #     # optsパラメータにredirect_urlを指定
  #     opts = { redirect_url: "http://localhost:5173" }
  #     mail = UserMailer.reset_password_instructions(user, token, opts)

  #     expect(mail.subject).to eq("パスワードの再設定をお願いします")
  #     expect(mail.to).to eq([user.email])
  #     expect(mail.from).to eq(["no-reply@example.com"])

  #     MAIL_BODY = [
  #       "パスワードリセット",
  #       "パスワードのリセットが要求されました。以下のリンクをクリックして、新しいパスワードを設定してください。",
  #       "パスワードをリセットする",
  #       "ボタンが動作しない場合は、以下のURLをブラウザにコピーしてアクセスしてください。",
  #       "もしパスワードリセットリクエストをしていない場合は、このメールを無視してください。パスワードは変更されません。",
  #       "localhost:5173/reset_password?reset_password_token=#{token}"
  #     ]
  #     MAIL_BODY.each do |line|
  #       expect(mail.body.encoded).to include(line)
  #     end
  #   end
  # end


  # --TODO:: email変更の画面を作成したらコメントアウトを解除する--

  # describe "email_changed" do
  #   it "renders the email changed notification email" do
  #     mail = UserMailer.email_changed(user)

  #     expect(mail.subject).to eq("メールアドレスが変更されました")
  #     expect(mail.to).to eq([user.email])
  #     expect(mail.from).to eq(["no-reply@example.com"])

  #     MAIL_BODY = [
  #       "メールアドレスが変更されました",
  #       "以下のリンクをクリックして、新しいメールアドレスを確認してください。",
  #       "メールアドレスを確認する",
  #       "ボタンが動作しない場合は、以下のURLをブラウザにコピーしてアクセスしてください。",
  #       "localhost:5173/confirm?confirmation_token=#{token}"
  #     ]
  #     MAIL_BODY.each do |line|
  #       expect(mail.body.encoded).to include(line)
  #     end
  #   end
  # end
end
