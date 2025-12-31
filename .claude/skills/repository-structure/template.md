# リポジトリ構造定義書

## 概要

プロジェクトのディレクトリ構造とファイル配置ルール（Rails API + フロントエンド）

## ルートディレクトリ構造（Rails API プロジェクト）

```
juku-cloud-backend/
├── .github/              # GitHub設定ファイル
│   └── workflows/        # GitHub Actions (CI/CD)
├── .claude/              # Claude設定
│   ├── skills/           # Claudeスキル定義
│   └── settings.json     # Claude設定ファイル
├── .steering/            # プロジェクト管理ドキュメント
│   └── ideas/            # アイデア・要件メモ
├── app/                  # アプリケーションコード（Railsメイン）
├── bin/                  # 実行可能スクリプト
├── config/               # 設定ファイル
├── db/                   # データベース関連
├── lib/                  # ライブラリ・カスタムモジュール
├── log/                  # ログファイル
├── public/               # 静的ファイル
├── spec/                 # RSpecテストコード
├── storage/              # Active Storage用ストレージ
├── tmp/                  # 一時ファイル
├── vendor/               # サードパーティライブラリ
├── .env.example          # 環境変数テンプレート
├── .gitignore            # Git除外設定
├── .rubocop.yml          # RuboCop設定
├── Gemfile               # gem依存関係定義
├── Gemfile.lock          # gem依存関係ロック
├── Rakefile              # Rakeタスク定義
└── README.md             # プロジェクト説明
```

## ソースコード構造

### Rails API (app/)

**レイヤードアーキテクチャを採用**

```
app/
├── controllers/
│   ├── api/
│   │   ├── v1/                    # APIバージョン1
│   │   │   ├── base_controller.rb # 基底コントローラー
│   │   │   ├── users_controller.rb
│   │   │   ├── lessons_controller.rb
│   │   │   └── grade_records_controller.rb
│   │   └── v2/                    # 将来のAPIバージョン2（予約）
│   └── application_controller.rb  # Rails基底コントローラー
│
├── models/                        # ActiveRecordモデル（ドメイン層）
│   ├── concerns/                  # モデル共通モジュール
│   │   ├── authenticatable.rb
│   │   └── timestampable.rb
│   ├── user.rb
│   ├── lesson.rb
│   └── grade_record.rb
│
├── services/                      # ビジネスロジック（アプリケーション層）
│   ├── user_service.rb
│   ├── lesson_service.rb
│   └── grade_record_service.rb
│
├── queries/                       # データベースクエリ（インフラ層）
│   ├── lesson_query.rb
│   ├── user_query.rb
│   └── grade_record_query.rb
│
├── serializers/                   # JSONシリアライザー（プレゼンテーション層）
│   ├── user_serializer.rb        # Alba使用
│   ├── lesson_serializer.rb
│   └── grade_record_serializer.rb
│
├── jobs/                          # ActiveJob（非同期処理）
│   ├── lesson_notification_job.rb
│   └── grade_notification_job.rb
│
├── mailers/                       # ActionMailer
│   ├── user_mailer.rb
│   └── lesson_mailer.rb
│
├── errors/                        # カスタムエラー
│   ├── authentication_error.rb
│   ├── authorization_error.rb
│   └── validation_error.rb
│
└── validators/                    # カスタムバリデーター
    ├── email_validator.rb
    └── password_strength_validator.rb
```

**レイヤーごとの責務:**
- **Controller:** リクエスト/レスポンス処理、認証チェック
- **Model:** データ構造定義、基本的なバリデーション
- **Service:** ビジネスロジック、トランザクション制御
- **Query:** 複雑なデータベースクエリ、N+1問題回避
- **Serializer:** JSONレスポンスの整形
- **Job:** 非同期処理（メール送信など）
- **Mailer:** メール送信ロジック

### フロントエンド (frontend/)

```
frontend/
├── src/
│   ├── components/       # Reactコンポーネント
│   │   ├── atoms/        # 基本コンポーネント
│   │   ├── molecules/    # 複合コンポーネント
│   │   ├── organisms/    # 複雑なコンポーネント
│   │   └── templates/    # テンプレート
│   ├── pages/            # ページコンポーネント
│   ├── hooks/            # カスタムフック
│   ├── stores/           # 状態管理
│   ├── services/         # APIクライアント
│   ├── utils/            # ユーティリティ
│   ├── types/            # 型定義
│   ├── styles/           # スタイル
│   └── App.tsx           # アプリケーションルート
└── public/               # 静的ファイル
```

## テストコード構造（RSpec）

```
spec/
├── controllers/          # コントローラーテスト
│   └── api/
│       └── v1/
│           ├── users_controller_spec.rb
│           ├── lessons_controller_spec.rb
│           └── grade_records_controller_spec.rb
│
├── models/               # モデルテスト
│   ├── user_spec.rb
│   ├── lesson_spec.rb
│   └── grade_record_spec.rb
│
├── services/             # サービステスト
│   ├── user_service_spec.rb
│   ├── lesson_service_spec.rb
│   └── grade_record_service_spec.rb
│
├── queries/              # クエリテスト
│   ├── lesson_query_spec.rb
│   └── user_query_spec.rb
│
├── serializers/          # シリアライザーテスト
│   ├── user_serializer_spec.rb
│   └── lesson_serializer_spec.rb
│
├── jobs/                 # ジョブテスト
│   └── lesson_notification_job_spec.rb
│
├── mailers/              # メーラーテスト
│   └── user_mailer_spec.rb
│
├── requests/             # リクエストテスト（統合テスト）
│   └── api/
│       └── v1/
│           ├── authentication_spec.rb
│           └── lessons_spec.rb
│
├── factories/            # FactoryBot定義
│   ├── users.rb
│   ├── lessons.rb
│   └── grade_records.rb
│
├── support/              # テストヘルパー
│   ├── request_helpers.rb
│   ├── authentication_helpers.rb
│   └── database_cleaner.rb
│
├── fixtures/             # フィクスチャデータ
│   └── files/
│
├── rails_helper.rb       # Rails用RSpec設定
└── spec_helper.rb        # 汎用RSpec設定
```

## ドキュメント構造

```
.steering/
└── docs/
    ├── product-requirements.md    # PRD
    ├── functional-design.md       # 機能設計書
    ├── architecture.md            # アーキテクチャ設計書
    ├── repository-structure.md    # リポジトリ構造定義書
    ├── development-guidelines.md  # 開発ガイドライン
    ├── glossary.md               # 用語集
    └── api/                      # API仕様書
        └── openapi.yaml

README.md                          # プロジェクト概要
```

## 命名規則

### ファイル名（Ruby/Rails）
- モデル: `snake_case.rb` (単数形、例: `user.rb`, `lesson.rb`)
- コントローラー: `snake_case_controller.rb` (複数形、例: `users_controller.rb`)
- サービス: `snake_case_service.rb` (例: `user_service.rb`)
- クエリ: `snake_case_query.rb` (例: `lesson_query.rb`)
- シリアライザー: `snake_case_serializer.rb` (例: `user_serializer.rb`)
- テスト: `*_spec.rb` (例: `user_spec.rb`)
- マイグレーション: `YYYYMMDDHHMMSS_action_table_name.rb` (例: `20250115120000_create_users.rb`)

### ファイル名（フロントエンド）
- Reactコンポーネント: `PascalCase.tsx`
- ユーティリティ: `camelCase.ts`
- テスト: `*.test.ts`

### ディレクトリ名
- 基本: `snake_case` (Ruby/Rails)
- フロントエンド: `kebab-case`

### 変数・関数・クラス名（Ruby）
- 変数・メソッド: `snake_case`
- 定数: `UPPER_SNAKE_CASE`
- クラス・モジュール: `PascalCase`
- 真偽値メソッド: `?` で終わる (例: `active?`, `valid?`)
- 破壊的メソッド: `!` で終わる (例: `save!`, `update!`)
- Privateメソッド: プレフィックスなし（`private`キーワードで制御）

## ファイル配置ルール

### 新規ファイル作成時（Rails）
1. **適切なレイヤーを判断する**
   - リクエスト/レスポンス処理 → `controllers/`
   - データ構造定義 → `models/`
   - ビジネスロジック → `services/`
   - 複雑なクエリ → `queries/`
   - JSON整形 → `serializers/`
   - 非同期処理 → `jobs/`

2. **既存の類似ファイルを参考にする**
   - 同じレイヤーのファイルを確認
   - 命名規則を踏襲

3. **関連ファイルは同じディレクトリに配置する**
   - `app/controllers/api/v1/` にすべてのv1コントローラーを配置
   - `app/services/` にすべてのサービスを配置（ディレクトリ分けしない）

4. **テストファイルは対応するソースファイルと同じ構造で配置する**
   - `app/models/user.rb` → `spec/models/user_spec.rb`
   - `app/services/user_service.rb` → `spec/services/user_service_spec.rb`

### Require順序（Ruby）
1. 標準ライブラリ
2. gem（外部ライブラリ）
3. アプリケーション内部モジュール

```ruby
# 標準ライブラリ
require 'json'
require 'securerandom'

# gem
require 'devise'
require 'alba'

# アプリケーション内部
require_relative '../services/user_service'
```

**注:** Railsでは`config/application.rb`の自動読み込み（autoload）機能により、通常はrequireが不要です。

## パス設定

### Rails自動読み込みパス

Railsは`app/`配下のディレクトリを自動的に読み込みます。カスタムディレクトリを追加する場合は`config/application.rb`に設定:

```ruby
# config/application.rb
module JukuCloudBackend
  class Application < Rails::Application
    # 自動読み込みパスの追加
    config.autoload_paths << Rails.root.join('lib')
    config.eager_load_paths << Rails.root.join('lib')

    # カスタムディレクトリの追加例
    # config.autoload_paths << Rails.root.join('app', 'queries')
    # config.autoload_paths << Rails.root.join('app', 'errors')
  end
end
```

## 環境ファイル管理

```
.env.example          # テンプレート (Git管理対象)
.env.development      # 開発環境 (Git管理対象外)
.env.test             # テスト環境 (Git管理対象外)
.env.staging          # ステージング環境 (Git管理対象外)
.env.production       # 本番環境 (Git管理対象外)
```

## Git管理ルール

### .gitignore に含めるもの
- `node_modules/`
- `.env` (except `.env.example`)
- `dist/`, `build/`
- ログファイル
- IDEの設定ファイル (`.vscode/`, `.idea/`)
- OS固有ファイル (`.DS_Store`, `Thumbs.db`)

### コミット対象
- ソースコード
- 設定ファイル
- ドキュメント
- テストコード
- `.env.example`

## スクリプト構造

### bin/ (Rails実行可能ファイル)
```
bin/
├── bundle                # Bundler wrapper
├── rails                 # Railsコマンド
├── rake                  # Rakeコマンド
├── rspec                 # RSpecテスト実行
└── setup                 # 初回セットアップスクリプト
```

### カスタムスクリプト（作成例）
```
lib/tasks/
├── seed.rake             # シードデータ投入タスク
├── deploy.rake           # デプロイタスク
└── backup.rake           # バックアップタスク
```

**Rakeタスク実行例:**
```bash
bundle exec rake db:seed
bundle exec rake deploy:production
bundle exec rake backup:create
```
