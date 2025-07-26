class UserMailer < ApplicationMailer
  default from: "no-reply@example.com"

  # 会員登録確認メール（メールアドレス変更確認も含む）
  def confirmation_instructions(user, token, opts = {})
    @user = user
    @token = token

    # userインスタンスからconfirm_success_urlを取得
    base_url = @user.confirm_success_url || opts[:confirm_success_url] || ENV["FRONTEND_URL"] || "http://localhost:5173/confirmed"
    @confirmation_url = "#{base_url}/confirm?confirmation_token=#{token}"

    # メールアドレス変更の場合は新しいアドレスに送信
    if @user.unconfirmed_email.present?
      mail(to: @user.unconfirmed_email, subject: "新しいメールアドレスの確認をお願いします")
    else
      mail(to: @user.email, subject: "メールアドレスの確認をお願いします")
    end
  end

  # パスワードリセットメール
  def reset_password_instructions(user, token, opts = {})
    @user = user
    @token = token
    @reset_password_url = "#{frontend_url(opts)}/reset_password?reset_password_token=#{token}"

    mail(to: @user.email, subject: "パスワードの再設定をお願いします")
  end

  # メール変更を通知するメール（古いメールアドレスに送信）
  def email_changed(user, opts = {})
    @user = user

    mail(to: @user.email, subject: "メールアドレスが変更されました")
  end

  # パスワード変更通知メール
  def password_change(user, opts = {})
    @user = user

    mail(to: @user.email, subject: "パスワードが変更されました")
  end

  private

  def frontend_url(opts = {})
    return opts[:confirm_success_url] if opts[:confirm_success_url].present?
    return ENV["FRONTEND_URL"] if ENV["FRONTEND_URL"].present?
    "http://localhost:5173/confirmed"
  end
end
