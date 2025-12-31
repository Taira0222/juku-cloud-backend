# 開発ガイドライン

## 概要

このドキュメントは、開発チーム全体で遵守すべきコーディング規約、開発フロー、ベストプラクティスを定義します。

## 開発環境セットアップ

### 必須ツール（Rails API）

- **Ruby:** 3.4.4
- **Bundler:** 最新版
- **PostgreSQL:** 15.x以上
- **Git:** 最新版
- **Docker & Docker Compose:** 最新版（推奨）

### 推奨ツール

- **VSCode**（推奨エディタ）
- **推奨VSCode拡張機能:**
  - Ruby（Peng Lv）
  - Ruby Solargraph
  - ERB Formatter/Beautify
  - Rails
  - Docker

### セットアップ手順（Rails API）

```bash
# リポジトリクローン
git clone <repository-url>
cd juku-cloud-backend

# Rubyバージョン確認
ruby -v  # 3.4.4 であることを確認

# 依存関係インストール
bundle install

# 環境変数設定
cp .env.example .env
# .env ファイルを編集してデータベース接続情報などを設定

# データベースセットアップ
bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rails db:seed

# テスト実行
bundle exec rspec

# 開発サーバー起動
bundle exec rails server
```

### Docker環境でのセットアップ

```bash
# コンテナ起動
docker-compose up -d

# データベースセットアップ
docker-compose exec app bundle exec rails db:create
docker-compose exec app bundle exec rails db:migrate
docker-compose exec app bundle exec rails db:seed

# テスト実行
docker-compose exec app bundle exec rspec

# ログ確認
docker-compose logs -f app
```

## コーディング規約

### Ruby/Rails

#### スタイルガイド

- [Ruby Style Guide](https://rubystyle.guide/)に準拠
- [Rails Style Guide](https://rails.rubystyle.guide/)に準拠
- RuboCopで自動チェック（`.rubocop.yml`）

#### 基本スタイル

**インデント:**
- スペース2つ（タブ禁止）

**行の長さ:**
- 最大120文字（RuboCop設定済み）

**文字列リテラル:**
- ダブルクォート `"` を優先（式展開・エスケープシーケンスを使用可能）

```ruby
# Good
name = "Juku Cloud"
message = "Hello, #{name}!"

# Bad
name = 'Juku Cloud'
message = 'Hello, ' + name + '!'
```

**ハッシュ記法:**
- シンボルキーの場合は新記法（`key: value`）を使用

```ruby
# Good
user = { name: "John", email: "john@example.com" }

# Bad
user = { :name => "John", :email => "john@example.com" }
```

#### Railsベストプラクティス

**Fat Modelを避ける:**
- ビジネスロジックはService層に配置
- Modelはデータ構造定義とバリデーションのみ

```ruby
# Good: ビジネスロジックをServiceに配置
class Students::CreateService
  def self.call(school:, create_params:)
    student = school.students.build(create_params)
    student.save!
    student
  end
end

# Bad: Modelにビジネスロジック
class Student < ApplicationRecord
  def self.create_with_subjects(params, subjects)
    transaction do
      student = create!(params)
      student.subjects << subjects
      # ... 複雑な処理
    end
  end
end
```

**コントローラーはシンプルに:**
- リクエスト/レスポンス処理のみ
- Service呼び出しとSerializer使用

```ruby
# Good
class Api::V1::StudentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_school!

  def create
    student = Students::CreateService.call(
      school: @school,
      create_params: create_params
    )
    render json: Students::CreateResource.new(student).serializable_hash,
           status: :created
  end

  private

  def create_params
    params.permit(:name, :school_stage, :grade, :joined_on)
  end
end

# Bad: コントローラーにビジネスロジック
class Api::V1::StudentsController < ApplicationController
  def create
    student = @school.students.build(create_params)
    if student.save
      student.subjects << Subject.find(params[:subject_ids])
      StudentMailer.welcome(student).deliver_later
      render json: student
    else
      render json: { errors: student.errors }, status: :unprocessable_entity
    end
  end
end
```

**N+1問題を回避:**
- `includes`, `preload`, `eager_load`を活用
- BulletによるN+1検出を有効化（開発環境）

```ruby
# Good: N+1問題を回避
students = school.students
  .includes(:class_subjects, :available_days, :teachers)
  .page(params[:page])

# Bad: N+1問題
students = school.students.page(params[:page])
students.each do |student|
  puts student.class_subjects.map(&:name)  # N+1発生
  puts student.teachers.map(&:name)        # N+1発生
end
```

**Strong Parameters:**
- 必ず使用
- ホワイトリスト方式でパラメータを許可

```ruby
# Good
def create_params
  params.permit(:name, :school_stage, :grade, :joined_on, subject_ids: [])
end

# Bad: Strong Parametersを使わない
def create
  student = Student.create(params[:student])  # セキュリティリスク
end
```

### 命名規則

#### Ruby/Rails

- **変数・メソッド:** `snake_case`
  - 例: `student_id`, `create_service`, `token_digest`
- **クラス・モジュール:** `PascalCase`
  - 例: `User`, `LessonNote`, `Students::CreateService`
- **定数:** `UPPER_SNAKE_CASE`
  - 例: `MAX_USES`, `DEFAULT_EXPIRES_AT`
- **真偽値メソッド:** `?`で終わる
  - 例: `active?`, `valid?`, `expired?`
- **破壊的メソッド:** `!`で終わる
  - 例: `save!`, `update!`, `destroy!`
- **Privateメソッド:** 先頭にアンダースコアなし（`private`キーワードで制御）

```ruby
class Students::CreateService
  MAX_RETRY_COUNT = 3

  def self.call(school:, create_params:)
    student = school.students.build(create_params)
    student.save!
    student
  end

  private_class_method def self.validate_params(params)
    # バリデーション処理
  end
end
```

### コメント

#### ドキュメントコメント

- 公開API、複雑なロジックには説明を記述
- RDocスタイルを推奨

```ruby
# 招待トークンを生成する
#
# @param school [School] 招待元のSchool
# @return [String] 生成された招待トークン
# @raise [StandardError] トークン生成に失敗した場合
def self.generate_token(school)
  # ...
end
```

#### インラインコメント

- **WHYを説明する**（WHATは説明しない）
- 複雑なロジックの意図を明確にする

```ruby
# Good: 理由を説明
# 同時実行を防ぐためにトークンをハッシュ化してDBに保存
token_digest = OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, raw_token)

# Bad: コードを繰り返しているだけ
# トークンをハッシュ化
token_digest = OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, raw_token)
```

## Git ワークフロー

### ブランチ戦略（GitHub Flow）

```
main                  # 本番環境（常にデプロイ可能な状態）
  └─ feature/xxx      # 機能開発
  └─ bugfix/xxx       # バグ修正
  └─ hotfix/xxx       # 緊急修正
```

### ブランチ命名規則

- `feature/[issue-number]-short-description`
- `bugfix/[issue-number]-short-description`
- `hotfix/[issue-number]-short-description`

**例:**
- `feature/123-teacher-invitation`
- `bugfix/456-fix-n-plus-one-query`
- `hotfix/789-fix-authentication-error`

### コミットメッセージ

#### フォーマット

```
<type>(<scope>): <subject>

<body>

<footer>
```

#### Type

- `feat`: 新機能
- `fix`: バグ修正
- `docs`: ドキュメント変更
- `style`: コードフォーマット（機能に影響なし）
- `refactor`: リファクタリング
- `test`: テスト追加・修正
- `chore`: ビルド・ツール設定変更

#### 例

```
feat(auth): 講師招待機能を追加

- HMAC-SHA256によるトークン生成を実装
- 招待トークンのバリデーション機能を追加
- 招待トークンのAPIエンドポイントを実装

Closes #123
```

### プルリクエスト

#### タイトル

- コミットメッセージと同じフォーマット
- 例: `feat(students): 生徒管理機能を追加`

#### 説明テンプレート

```.github/PULL_REQUEST_TEMPLATE.md`に定義済み）

```markdown
## 概要
変更内容の概要を記述

## 変更内容
- 変更点1
- 変更点2
- 変更点3

## テスト
- [ ] ユニットテスト追加
- [ ] 統合テスト追加
- [ ] 手動テスト実施

## スクリーンショット（必要な場合）

## 関連Issue
Closes #123
```

#### レビュー基準

1. **機能性:** 要件を満たしているか
2. **テスト:** 十分にテストされているか（カバレッジLine 90%以上）
3. **コーディング規約:** RuboCopをパスしているか
4. **セキュリティ:** 脆弱性がないか（Brakeman）
5. **パフォーマンス:** N+1問題がないか（Bullet）
6. **可読性:** コードが理解しやすいか

## テスト

### テスト戦略

- **ユニットテスト:** モデル・サービス・クエリ単位
- **統合テスト:** リクエストテスト（APIエンドポイント）
- **カバレッジ目標:** Line 90%以上、Branch 80%以上（現在: Line 98%, Branch 89%）

### テストフレームワーク

- **RSpec:** テストフレームワーク
- **FactoryBot:** テストデータ生成
- **SimpleCov:** コードカバレッジ計測

### テスト命名規則

```ruby
RSpec.describe Students::CreateService do
  describe '.call' do
    context 'when valid params' do
      it 'creates a new student' do
        # ...
      end

      it 'returns the created student' do
        # ...
      end
    end

    context 'when invalid params' do
      it 'raises an error' do
        # ...
      end
    end
  end
end
```

### テストのベストプラクティス

- **AAAパターン（Arrange, Act, Assert）を使用**
  - Arrange: テストデータの準備
  - Act: テスト対象の実行
  - Assert: 結果の検証

```ruby
it 'creates a new student' do
  # Arrange
  school = create(:school)
  params = { name: 'John Doe', school_stage: 'junior_high_school', grade: 2 }

  # Act
  student = Students::CreateService.call(school: school, create_params: params)

  # Assert
  expect(student).to be_persisted
  expect(student.name).to eq('John Doe')
end
```

- **1テスト1アサーション（可能な限り）**
- **テストは独立させる**（他のテストに依存しない）
- **FactoryBotを活用**してテストデータを生成

```ruby
# FactoryBot定義
FactoryBot.define do
  factory :student do
    school
    name { 'John Doe' }
    school_stage { :junior_high_school }
    grade { 2 }
    joined_on { Date.current }
    status { :active }
  end
end

# テストで使用
student = create(:student)  # DBに保存
student = build(:student)   # メモリ上のみ
```

### テスト実行

```bash
# すべてのテストを実行
bundle exec rspec

# 特定のファイルのみ実行
bundle exec rspec spec/models/user_spec.rb

# 特定の行のみ実行
bundle exec rspec spec/models/user_spec.rb:10

# カバレッジレポート生成
COVERAGE=true bundle exec rspec
```

## セキュリティ

### 入力値検証

- **すべてのユーザー入力を検証する**
- **Strong Parametersを使用**
- **ホワイトリスト方式を採用**

```ruby
# Good
def create_params
  params.permit(:name, :email, :school_stage, :grade)
end

# Bad: すべてのパラメータを許可
def create_params
  params.permit!
end
```

### 認証・認可

- **パスワードはハッシュ化して保存**（bcrypt、cost=12）
- **JWTトークンは短い有効期限を設定**（24時間）
- **センシティブな操作には権限チェック**（`require_admin_role!`）

```ruby
class Api::V1::StudentsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin_role!, only: %i[create update destroy]
end
```

### 機密情報管理

- **環境変数で管理**（`.env`ファイル）
- **コードに直接記述しない**
- **Git にコミットしない**（`.gitignore`に`.env`を追加）

```ruby
# Good: 環境変数を使用
secret_key = ENV['SECRET_KEY']

# Bad: ハードコーディング
secret_key = 'my-secret-key-12345'
```

### セキュリティスキャン

- **Brakeman:** 脆弱性の静的解析
- **Bundler Audit:** 依存ライブラリの脆弱性チェック

```bash
# Brakeman実行
bundle exec brakeman

# Bundler Audit実行
bundle exec bundle audit check --update
```

## パフォーマンス

### データベース

**N+1問題を避ける:**

```ruby
# Good: Eager Loading
students = school.students.includes(:class_subjects, :teachers)

# Bad: N+1問題
students = school.students.all
students.each { |student| puts student.class_subjects.count }
```

**適切なインデックスを設定:**

```ruby
# マイグレーション
add_index :students, :school_id
add_index :lesson_notes, :student_class_subject_id
add_index :invites, :token_digest, unique: true
```

**クエリを最適化:**
- Queryオブジェクトで複雑なクエリを分離
- `select`で必要なカラムのみ取得
- `pluck`で配列として取得

### API

- **ページネーションを実装**（Kaminari、デフォルト20件/ページ）
- **レスポンスをキャッシュする**（将来実装予定）
- **不要なデータを返さない**（Serializerで必要な情報のみ）

```ruby
# Kaminari使用例
students = school.students.page(params[:page]).per(params[:perPage] || 20)
```

## エラーハンドリング

### 統一されたエラーレスポンス

```ruby
# ApplicationControllerでの統一処理
class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActionController::ParameterMissing, with: :parameter_missing

  private

  def record_not_found(exception)
    render json: { error: exception.message }, status: :not_found
  end

  def parameter_missing(exception)
    render json: { error: exception.message }, status: :bad_request
  end
end
```

## デプロイメント

### デプロイフロー（GitHub Actions）

1. mainブランチへのpush/マージをトリガー
2. RSpecテスト実行
3. RuboCop実行
4. Dockerイメージビルド
5. ECRへプッシュ
6. ECSタスク定義更新
7. ECSサービス更新
8. `rails db:migrate`自動実行

### デプロイ前チェックリスト

- [ ] すべてのテストが通過（Line 90%以上）
- [ ] RuboCopをパス
- [ ] Brakemanで脆弱性なし
- [ ] コードレビュー完了
- [ ] マイグレーションスクリプト確認
- [ ] 環境変数設定確認

## コードレビューガイドライン

### レビュアーの責任

- **24時間以内にレビュー開始**
- **建設的なフィードバックを提供**
- **コードだけでなく、設計も確認**

### レビュー観点

1. **機能性:** 要件を満たしているか
2. **可読性:** コードが理解しやすいか
3. **保守性:** 変更・拡張しやすいか
4. **テスト:** 十分にテストされているか（カバレッジ90%以上）
5. **セキュリティ:** 脆弱性がないか
6. **パフォーマンス:** N+1問題がないか

## 禁止事項

### コード

- ❌ `puts`, `p`を本番コードに含めない（デバッグ用途のみ）
- ❌ ハードコーディング（マジックナンバー、URL等）
- ❌ グローバル変数の使用
- ❌ コントローラーにビジネスロジックを記述

### Git

- ❌ 直接mainブランチへのプッシュ
- ❌ 大量の変更を含む単一コミット（1コミット1機能）
- ❌ 意味のないコミットメッセージ（`fix`, `update`のみ）

## 開発ツール

### RuboCop（静的解析）

```bash
# 実行
bundle exec rubocop

# 自動修正
bundle exec rubocop -a
```

### Bullet（N+1検出）

- 開発環境で自動的に有効化
- N+1問題を検出すると警告を表示

### SimpleCov（カバレッジ計測）

```bash
# カバレッジレポート生成
COVERAGE=true bundle exec rspec

# レポート確認
open coverage/index.html
```

## トラブルシューティング

### よくある問題と解決方法

#### 問題: bundle installが失敗する

```bash
# Bundlerキャッシュをクリア
bundle clean --force
bundle install
```

#### 問題: データベース接続エラー

```bash
# データベースを再作成
bundle exec rails db:drop
bundle exec rails db:create
bundle exec rails db:migrate
```

#### 問題: RuboCopエラーが大量に出る

```bash
# 自動修正を実行
bundle exec rubocop -a
```

## 参考資料

- [Ruby Style Guide](https://rubystyle.guide/)
- [Rails Style Guide](https://rails.rubystyle.guide/)
- [RSpec Best Practices](https://www.betterspecs.org/)
- [Rails API Documentation](https://api.rubyonrails.org/)
- [devise_token_auth Documentation](https://devise-token-auth.gitbook.io/)
