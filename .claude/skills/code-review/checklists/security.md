# Security Review Checklist

このチェックリストは、`docs/development-guidelines.md`のセキュリティセクションに基づくセキュリティベストプラクティス遵守を検証するためのルール集です。

**参照**: `/app/juku-cloud-backend/docs/development-guidelines.md` (Security section)

---

## Authentication & Authorization

### Rule: SEC-001
**Description**: Strong Parametersが使用されていること（ホワイトリスト方式）
**Check**:
- ControllerでStrong Parametersが使用されているか
- `permit!`（全パラメータ許可）が使用されていないか
- 許可するパラメータがホワイトリスト形式で明示されているか
**Severity**: Critical
**Good Example**:
```ruby
def student_params
  params.require(:student).permit(:name, :school_stage, :grade, :joined_on, :status)
end
```
**Bad Example**:
```ruby
def student_params
  params.require(:student).permit!  # 全パラメータ許可（危険）
end

# または
def create
  student = Student.create!(params[:student])  # Strong Parameters未使用（危険）
end
```

---

### Rule: SEC-002
**Description**: 認証チェック（authenticate_user!）が実装されていること
**Check**:
- APIエンドポイントに`before_action :authenticate_user!`が設定されているか
- 公開エンドポイント（例: ユーザー登録）以外は認証必須か
**Severity**: Critical
**Good Example**:
```ruby
class Api::V1::StudentsController < ApplicationController
  before_action :authenticate_user!  # 認証必須

  def index
    students = @school.students
    render json: students
  end
end
```
**Bad Example**:
```ruby
class Api::V1::StudentsController < ApplicationController
  # authenticate_user! が欠落

  def index
    students = Student.all  # 認証なしで全データ取得可能（危険）
    render json: students
  end
end
```

---

### Rule: SEC-003
**Description**: 認可チェック（require_admin_role!等）が実装されていること
**Check**:
- 管理者限定機能に`before_action :require_admin_role!`が設定されているか
- ユーザーが自分のSchoolのデータのみアクセスできるようスコープされているか
**Severity**: Critical
**Good Example**:
```ruby
class Api::V1::InvitesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin_role!, only: :create  # 管理者のみ作成可能

  def create
    invite = Invites::TokenGenerate.call(@school)
    render json: { token: invite }, status: :created
  end
end
```
**Bad Example**:
```ruby
class Api::V1::StudentsController < ApplicationController
  before_action :authenticate_user!

  def show
    student = Student.find(params[:id])  # 他のSchoolの生徒も取得可能（危険）
    render json: student
  end
end

# Good（認可あり）
def show
  student = @school.students.find(params[:id])  # 自分のSchoolの生徒のみ
  render json: student
end
```

---

### Rule: SEC-004
**Description**: パスワードがハッシュ化されていること（bcrypt, cost=12）
**Check**:
- パスワードが平文で保存されていないか
- bcryptでハッシュ化されているか（devise/has_secure_password使用）
- costが12以上か
**Severity**: Critical
**Good Example**:
```ruby
# Gemfile
gem "bcrypt", "~> 3.1.7"

# app/models/user.rb
class User < ApplicationRecord
  has_secure_password  # bcryptでハッシュ化
end

# または devise使用
gem "devise"
gem "devise_token_auth"
```
**Note**: このプロジェクトでは`devise_token_auth`を使用

---

### Rule: SEC-005
**Description**: JWTトークンに有効期限が設定されていること
**Check**:
- トークンに`expires_at`または有効期限が設定されているか
- 期限切れトークンが拒否されるか
**Severity**: Critical
**Good Example**:
```ruby
# app/models/invite.rb
class Invite < ApplicationRecord
  def expired?
    expires_at.present? && Time.current > expires_at
  end
end

# デフォルト有効期限: 7日間
expires_at ||= 7.days.from_now
```
**Note**: このプロジェクトでは`devise_token_auth`のデフォルト設定で24時間

---

## Sensitive Data Management

### Rule: SEC-006
**Description**: 機密情報がENV変数で管理されていること
**Check**:
- API Key、シークレットキー、パスワードがENV変数で管理されているか
- `.env`ファイルが`.gitignore`に含まれているか
**Severity**: Critical
**Good Example**:
```ruby
# config/database.yml
production:
  url: <%= ENV["DATABASE_URL"] %>

# app/services/external_api_service.rb
API_KEY = ENV["EXTERNAL_API_KEY"]
```
**Bad Example**:
```ruby
API_KEY = "sk_live_1234567890abcdef"  # ハードコーディング（危険）
database_password = "my_password_123"  # ハードコーディング（危険）
```

---

### Rule: SEC-007
**Description**: ハードコーディングされた機密情報が存在しないこと
**Check**:
- コード内にパスワード・API Key・シークレットキーが直接記述されていないか
- 設定ファイル（config/）に機密情報がハードコーディングされていないか
**Severity**: Critical
**Indicators**:
- `password = "..."`
- `api_key = "sk_..."`
- `secret_key = "..."`
- `token = "eyJ..."`

---

### Rule: SEC-008
**Description**: `.env`ファイルがコミットされていないこと
**Check**:
- `.env`ファイルが`.gitignore`に含まれているか
- Git履歴に`.env`ファイルが含まれていないか
**Severity**: Critical
**Good Example**:
```
# .gitignore
.env
.env.local
.env.*.local
```

---

## Injection Attacks Prevention

### Rule: SEC-009
**Description**: SQLインジェクション対策が実装されていること
**Check**:
- 生SQLにユーザー入力が直接結合されていないか
- プレースホルダ（パラメータ化クエリ）が使用されているか
**Severity**: Critical
**Good Example**:
```ruby
# プレースホルダ使用（安全）
students = Student.where("name ILIKE ?", "%#{params[:keyword]}%")

# ActiveRecordのメソッド使用（安全）
students = Student.where(name: params[:name])
```
**Bad Example**:
```ruby
# 生SQL + 文字列結合（危険）
students = Student.where("name = '#{params[:name]}'")
```

---

### Rule: SEC-010
**Description**: XSS（クロスサイトスクリプティング）対策が実装されていること
**Check**:
- ユーザー入力がそのままHTMLに出力されていないか
- サニタイゼーション・エスケープ処理が行われているか
**Severity**: Critical
**Note**: RailsのAPI modeではHTML出力がないため、通常XSSリスクは低い。ただし、管理画面等でHTMLを返す場合は注意。
**Good Example**:
```erb
<%# Rails自動エスケープ %>
<%= @student.name %>

<%# 手動サニタイゼーション %>
<%= sanitize(@student.description) %>
```

---

### Rule: SEC-011
**Description**: CSRF（クロスサイトリクエストフォージェリ）対策が実装されていること
**Check**:
- Railsの`protect_from_forgery`が有効か
**Severity**: Info
**Note**: このプロジェクトはAPI modeでトークン認証（devise_token_auth）を使用しているため、CSRFリスクは限定的。ただし、Cookieベースの認証を追加する場合は要注意。

---

## Token & Password Security

### Rule: SEC-012
**Description**: トークンが安全に生成されていること
**Check**:
- `SecureRandom`を使用してトークンが生成されているか
- 予測可能なトークン生成（例: `rand`, `Time.now.to_i`）が使用されていないか
**Severity**: Critical
**Good Example**:
```ruby
raw_token = SecureRandom.urlsafe_base64(32)  # 暗号学的に安全
```
**Bad Example**:
```ruby
token = rand(1000000).to_s  # 予測可能（危険）
token = Time.now.to_i.to_s  # 予測可能（危険）
```

---

### Rule: SEC-013
**Description**: トークンがハッシュ化されてDB保存されていること
**Check**:
- 生トークン（raw token）がDBに保存されていないか
- ハッシュ化されたトークン（digest）がDB保存されているか
**Severity**: Critical
**Good Example**:
```ruby
# app/models/invite.rb
def self.digest(raw_token)
  secret = Rails.application.secret_key_base
  OpenSSL::HMAC.hexdigest("SHA256", secret, raw_token)
end

# Service
raw_token = SecureRandom.urlsafe_base64(32)
digest = Invite.digest(raw_token)
Invite.create!(token_digest: digest)  # digestのみ保存

# 生トークンはレスポンスで返すのみ
{ token: raw_token }
```
**Bad Example**:
```ruby
raw_token = SecureRandom.urlsafe_base64(32)
Invite.create!(token: raw_token)  # 生トークンを保存（危険）
```

---

### Rule: SEC-014
**Description**: パスワードリセット・トークン再生成に回数制限があること
**Check**:
- レート制限（rate limiting）が実装されているか
- ブルートフォース攻撃対策があるか
**Severity**: Warning
**Note**: 将来実装予定（現在は未実装）

---

## Data Access Control

### Rule: SEC-015
**Description**: データアクセスが適切にスコープされていること
**Check**:
- 全データ取得（`Model.all`）が使用されていないか
- ユーザーの所属Schoolにスコープされているか
**Severity**: Critical
**Good Example**:
```ruby
# Schoolにスコープ
students = @school.students

# 自分が作成したデータのみ
reports = current_user.reports
```
**Bad Example**:
```ruby
# 全データ取得（危険）
students = Student.all
reports = Report.all
```

---

## Logging & Monitoring

### Rule: SEC-016
**Description**: 機密情報がログに出力されていないこと
**Check**:
- パスワード・トークン・API Keyがログに記録されていないか
- Railsの`filter_parameters`でフィルタリングされているか
**Severity**: Warning
**Good Example**:
```ruby
# config/initializers/filter_parameter_logging.rb
Rails.application.config.filter_parameters += [
  :password, :password_confirmation, :token, :api_key, :secret
]
```

---

## Security Scan Tools

### Rule: SEC-017
**Description**: Brakemanで脆弱性が検出されていないこと
**Check**:
- `bundle exec brakeman`を実行し、脆弱性が0件か
**Severity**: Critical
**Note**: レビュー後、必ずBrakemanを実行してください

---

### Rule: SEC-018
**Description**: Bundler Auditで依存ライブラリの脆弱性が検出されていないこと
**Check**:
- `bundle audit`を実行し、脆弱性が0件か
**Severity**: Warning
**Note**: 定期的にBundler Auditを実行し、依存ライブラリを更新してください

---

## Summary

このチェックリストにより、以下が保証されます：

1. **認証・認可**: authenticate_user!, require_admin_role!, データスコープ
2. **パラメータ検証**: Strong Parameters（ホワイトリスト方式）
3. **機密情報管理**: ENV変数、ハードコーディング禁止、.env除外
4. **インジェクション攻撃防止**: SQLインジェクション、XSS対策
5. **トークン・パスワードセキュリティ**: bcrypt、SecureRandom、ハッシュ化
6. **データアクセス制御**: Schoolスコープ、全データ取得禁止
7. **ツール活用**: Brakeman、Bundler Audit

**重要**: セキュリティ問題は全てCritical扱いとし、マージ前に必ず修正してください。
