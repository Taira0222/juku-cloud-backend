module RequestSpecHelper
  # DeviseTokenAuthの認証ヘッダーを生成
  def auth_headers_for(user)
    return {} if user.nil?
    # 認証トークンを生成
    user.create_new_auth_token
  end

  # 認証付きHTTPメソッド
  %w[get post put patch delete].each do |method|
    define_method("#{method}_with_auth") do |path, user, params: {}, **options|
      headers = auth_headers_for(user)

      # JSONリクエストの場合のContent-Typeを自動設定
      if %w[post put patch].include?(method) && !options[:as]
        options[:as] = :json
      end

      send(method, path, params: params, headers: headers, **options)
    end
  end

  # 認証が必要なエンドポイントのテスト用ヘルパー
  # def expect_authentication_required(path, method: :get, params: {})
  #   send(method, path, params: params)
  #   expect(response).to have_http_status(:unauthorized)
  # end
end
