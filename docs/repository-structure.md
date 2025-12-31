# リポジトリ構造定義書

## 概要

Juku Cloud Backendのディレクトリ構造とファイル配置ルール（Rails 8.0 API mode）を定義します。

## ルートディレクトリ構造

```
juku-cloud-backend/
├── .github/              # GitHub設定ファイル
│   └── workflows/        # GitHub Actions (CI/CD)
├── .claude/              # Claude Code設定
│   ├── skills/           # Claudeスキル定義
│   └── commands/         # カスタムコマンド
├── .steering/            # プロジェクト管理ドキュメント
│   └── idea/             # アイデア・要件メモ
├── app/                  # アプリケーションコード（Railsメイン）
├── bin/                  # 実行可能スクリプト
├── config/               # 設定ファイル
├── db/                   # データベース関連
├── docs/                 # プロジェクトドキュメント
├── ecs/                  # ECS設定ファイル
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

**レイヤードアーキテクチャを採用:**

```
app/
├── controllers/
│   ├── api/
│   │   └── v1/                        # APIバージョン1
│   │       ├── dashboards_controller.rb
│   │       ├── health_check_controller.rb
│   │       ├── invites_controller.rb
│   │       ├── lesson_notes_controller.rb
│   │       ├── students_controller.rb
│   │       ├── student_traits_controller.rb
│   │       └── teachers_controller.rb
│   ├── concerns/                      # コントローラー共通モジュール
│   │   ├── ensure_student_access.rb
│   │   ├── error_handling.rb
│   │   ├── require_admin_role.rb
│   │   └── set_school.rb
│   └── application_controller.rb      # Rails基底コントローラー
│
├── models/                            # ActiveRecordモデル（ドメイン層）
│   ├── availability/                  # 空き時間管理
│   │   ├── student_link.rb
│   │   └── user_link.rb
│   ├── subjects/                      # 科目管理
│   │   ├── student_link.rb
│   │   └── user_link.rb
│   ├── teaching/                      # 教師割り当て
│   │   └── assignment.rb
│   ├── application_record.rb
│   ├── available_day.rb
│   ├── class_subject.rb
│   ├── invite.rb
│   ├── lesson_note.rb
│   ├── school.rb
│   ├── student.rb
│   ├── student_trait.rb
│   └── user.rb
│
├── serializers/                       # Albaシリアライザー（プレゼンテーション層）
│   ├── dashboards/
│   │   └── show_resource.rb
│   ├── invites/
│   ├── lesson_notes/
│   │   ├── create_resource.rb
│   │   ├── index_resource.rb
│   │   └── update_resource.rb
│   ├── students/
│   │   ├── create_resource.rb
│   │   ├── index_resource.rb
│   │   └── update_resource.rb
│   ├── student_traits/
│   │   └── index_resource.rb
│   └── teachers/
│       └── index_resource.rb
│
├── services/                          # ビジネスロジック（アプリケーション層）
│   ├── invites/
│   │   ├── token_generate.rb
│   │   └── validator.rb
│   ├── lesson_notes/
│   │   ├── create_service.rb
│   │   ├── updater.rb
│   │   └── validator.rb
│   ├── students/
│   │   ├── create_service.rb
│   │   ├── updater.rb
│   │   └── validator.rb
│   └── student_traits/
│       ├── delete_service.rb
│       └── upsert_service.rb
│
├── queries/                           # データベースクエリ（インフラ層）
│   ├── dashboards/
│   │   └── show_query.rb
│   ├── lesson_notes/
│   │   └── index_query.rb
│   ├── students/
│   │   └── index_query.rb
│   ├── student_traits/
│   │   └── index_query.rb
│   └── teachers/
│       └── index_query.rb
│
├── jobs/                              # ActiveJob（非同期処理）
│   └── application_job.rb
│
└── mailers/                           # ActionMailer
    └── application_mailer.rb
```

**レイヤーごとの責務:**
- **Controller:** リクエスト/レスポンス処理、認証チェック、Service呼び出し
- **Model:** データ構造定義、バリデーション、アソシエーション
- **Service:** ビジネスロジック実装、トランザクション管理、複数モデル操作
- **Query:** 複雑なデータ取得、N+1問題回避、検索ロジック
- **Serializer:** JSONレスポンス整形、機密情報除外
- **Job:** 非同期処理（メール送信、バッチ処理）
- **Mailer:** メール送信ロジック

## テストコード構造（RSpec）

```
spec/
├── factories/                         # FactoryBot定義
│   ├── available_days.rb
│   ├── class_subjects.rb
│   ├── invites.rb
│   ├── lesson_notes.rb
│   ├── schools.rb
│   ├── students.rb
│   ├── student_traits.rb
│   └── users.rb
│
├── models/                            # モデルテスト
│   ├── invite_spec.rb
│   ├── lesson_note_spec.rb
│   ├── school_spec.rb
│   ├── student_spec.rb
│   └── user_spec.rb
│
├── requests/                          # リクエストテスト（統合テスト）
│   └── api/
│       └── v1/
│           ├── invites_spec.rb
│           ├── lesson_notes_spec.rb
│           ├── students_spec.rb
│           └── teachers_spec.rb
│
├── services/                          # サービステスト
│   ├── invites/
│   │   ├── token_generate_spec.rb
│   │   └── validator_spec.rb
│   ├── lesson_notes/
│   │   ├── create_service_spec.rb
│   │   └── updater_spec.rb
│   └── students/
│       ├── create_service_spec.rb
│       └── updater_spec.rb
│
├── queries/                           # クエリテスト
│   ├── lesson_notes/
│   │   └── index_query_spec.rb
│   └── students/
│       └── index_query_spec.rb
│
├── serializers/                       # シリアライザーテスト
│   ├── lesson_notes/
│   │   └── index_resource_spec.rb
│   └── students/
│       └── index_resource_spec.rb
│
├── support/                           # テストヘルパー
│   ├── database_cleaner.rb
│   └── factory_bot.rb
│
├── rails_helper.rb                   # Rails用RSpec設定
└── spec_helper.rb                    # 汎用RSpec設定
```

## ドキュメント構造

```
docs/
├── product-requirements.md           # プロダクト要求定義書
├── functional-design.md              # 機能設計書
├── architecture.md                   # アーキテクチャ設計書
├── repository-structure.md           # リポジトリ構造定義書（このファイル）
├── development-guidelines.md         # 開発ガイドライン
└── glossary.md                       # 用語集

README.md                             # プロジェクト概要
```

## 命名規則

### ファイル名（Ruby/Rails）

- **モデル:** `snake_case.rb`（単数形）
  - 例: `user.rb`, `lesson_note.rb`, `invite.rb`
- **コントローラー:** `snake_case_controller.rb`（複数形）
  - 例: `students_controller.rb`, `lesson_notes_controller.rb`
- **サービス:** `機能名/アクション.rb`
  - 例: `students/create_service.rb`, `invites/token_generate.rb`
- **クエリ:** `機能名/index_query.rb`
  - 例: `students/index_query.rb`, `lesson_notes/index_query.rb`
- **シリアライザー:** `機能名/アクション_resource.rb`
  - 例: `students/index_resource.rb`, `students/create_resource.rb`
- **テスト:** `*_spec.rb`
  - 例: `user_spec.rb`, `students_controller_spec.rb`
- **マイグレーション:** `YYYYMMDDHHMMSS_action_table_name.rb`
  - 例: `20250115120000_create_users.rb`, `20250116100000_add_status_to_students.rb`

### ディレクトリ名

- **基本:** `snake_case`
  - 例: `lesson_notes/`, `student_traits/`
- **名前空間:** 複数形を使用
  - 例: `app/models/subjects/`, `app/services/invites/`

### 変数・関数・クラス名（Ruby）

- **変数・メソッド:** `snake_case`
  - 例: `student_id`, `create_service`, `token_digest`
- **定数:** `UPPER_SNAKE_CASE`
  - 例: `MAX_USES`, `DEFAULT_EXPIRES_AT`
- **クラス・モジュール:** `PascalCase`
  - 例: `User`, `LessonNote`, `Students::CreateService`
- **真偽値メソッド:** `?` で終わる
  - 例: `active?`, `valid?`, `expired?`
- **破壊的メソッド:** `!` で終わる
  - 例: `save!`, `update!`, `destroy!`

## ファイル配置ルール

### 新規ファイル作成時（Rails）

1. **適切なレイヤーを判断する**
   - リクエスト/レスポンス処理 → `controllers/api/v1/`
   - データ構造定義 → `models/`
   - ビジネスロジック → `services/機能名/`
   - 複雑なクエリ → `queries/機能名/`
   - JSON整形 → `serializers/機能名/`
   - 非同期処理 → `jobs/`

2. **既存の類似ファイルを参考にする**
   - 同じレイヤーのファイルを確認
   - 命名規則を踏襲
   - 名前空間の使い方を統一

3. **名前空間で関連ファイルをグループ化する**
   - `app/services/students/` に生徒関連のサービスを配置
   - `app/serializers/students/` に生徒関連のシリアライザを配置

4. **テストファイルは対応するソースファイルと同じ構造で配置する**
   - `app/models/user.rb` → `spec/models/user_spec.rb`
   - `app/services/students/create_service.rb` → `spec/services/students/create_service_spec.rb`

### モジュール・名前空間の使い方

```ruby
# app/services/students/create_service.rb
module Students
  class CreateService
    def self.call(school:, create_params:)
      # ...
    end
  end
end

# 使用例
Students::CreateService.call(school: @school, create_params: params)
```

## パス設定

### Rails自動読み込みパス

Railsは`app/`配下のディレクトリを自動的に読み込みます。カスタムディレクトリを追加する場合は`config/application.rb`に設定:

```ruby
# config/application.rb
module JukuCloudBackend
  class Application < Rails::Application
    config.load_defaults 8.0
    config.api_only = true

    # 自動読み込みパスの追加（必要に応じて）
    # config.autoload_paths << Rails.root.join('lib')
    # config.eager_load_paths << Rails.root.join('lib')
  end
end
```

## 環境ファイル管理

```
.env.example          # テンプレート（Git管理対象）
.env.development      # 開発環境（Git管理対象外）
.env.test             # テスト環境（Git管理対象外）
.env.production       # 本番環境（Git管理対象外）
```

**環境変数の例:**
```bash
# .env.example
POSTGRES_USER=postgres
POSTGRES_PASSWORD=password
POSTGRES_DB=juku_cloud_backend_development
DB_HOST=localhost
DB_PORT=5432
RAILS_MAX_THREADS=5
```

## Git管理ルール

### .gitignore に含めるもの

- `log/*.log`
- `tmp/**/*`
- `.env`（except `.env.example`）
- `node_modules/`
- `storage/`（Active Storage用ファイル）
- IDEの設定ファイル（`.vscode/`, `.idea/`）
- OS固有ファイル（`.DS_Store`, `Thumbs.db`）

### コミット対象

- ソースコード（`app/`, `lib/`, `config/`）
- 設定ファイル（`.rubocop.yml`, `Gemfile`）
- ドキュメント（`docs/`, `README.md`）
- テストコード（`spec/`）
- `.env.example`（環境変数のテンプレート）
- マイグレーションファイル（`db/migrate/`）

### コミットしないもの

- ログファイル（`log/*.log`）
- 一時ファイル（`tmp/`）
- 環境変数ファイル（`.env`, `.env.local`）
- ビルド成果物（`public/packs/`）
- 依存ライブラリ（`vendor/bundle/`）

## スクリプト構造

### bin/（Rails実行可能ファイル）

```
bin/
├── bundle                # Bundler wrapper
├── rails                 # Railsコマンド
├── rake                  # Rakeコマンド
├── rspec                 # RSpecテスト実行
└── setup                 # 初回セットアップスクリプト
```

### カスタムスクリプト（lib/tasks/）

```
lib/tasks/
├── seed.rake             # シードデータ投入タスク
└── deploy.rake           # デプロイタスク（将来実装予定）
```

**Rakeタスク実行例:**
```bash
bundle exec rake db:seed
bundle exec rake db:migrate
bundle exec rspec
```

## 設定ファイル構造

### config/

```
config/
├── application.rb                    # Railsアプリケーション設定
├── boot.rb                           # ブート設定
├── database.yml                      # データベース設定
├── environment.rb                    # 環境設定ロード
├── routes.rb                         # ルーティング定義
├── puma.rb                           # Pumaサーバー設定
├── environments/                     # 環境別設定
│   ├── development.rb
│   ├── test.rb
│   └── production.rb
└── initializers/                     # イニシャライザ
    ├── bullet.rb                     # Bullet（N+1検出）設定
    ├── cors.rb                       # CORS設定
    ├── devise.rb                     # Devise設定
    ├── devise_token_auth.rb          # DeviseTokenAuth設定
    ├── filter_parameter_logging.rb   # ログフィルタ設定
    └── wrap_parameters.rb            # パラメータラップ設定
```

## データベース構造

### db/

```
db/
├── migrate/                          # マイグレーションファイル
│   ├── 20250101000000_create_schools.rb
│   ├── 20250102000000_create_users.rb
│   ├── 20250103000000_create_students.rb
│   ├── 20250104000000_create_lesson_notes.rb
│   └── 20250105000000_create_invites.rb
├── schema.rb                         # 現在のスキーマ定義
└── seeds.rb                          # シードデータ
```

## ECS設定構造

### ecs/

```
ecs/
└── taskdef.json                      # ECSタスク定義（CI/CDでレンダリング）
```

## 禁止事項

### ディレクトリ構造

- ❌ `app/`配下に独自の深い階層を作らない（Railsの規約に従う）
- ❌ `lib/`に本来`app/services/`に置くべきビジネスロジックを配置しない
- ❌ `concerns/`に複数の責務を持つ肥大化したモジュールを作らない

### ファイル配置

- ❌ コントローラーにビジネスロジックを直接記述しない
- ❌ モデルにプレゼンテーション層の処理（JSON整形等）を含めない
- ❌ 1ファイル1000行以上のコードを書かない（リファクタリング対象）

### 命名

- ❌ 省略形・略語を過度に使用しない（`usr` → `user`, `ln` → `lesson_note`）
- ❌ 日本語ローマ字を使用しない（`seito` → `student`）
- ❌ 数字で始まる変数名を使用しない（`1st_name` → `first_name`）

## ベストプラクティス

### ファイル分割

- 1クラス1ファイルの原則を守る
- 複雑なクラスは責務ごとに分割する
- 関連するクラスは名前空間でグループ化する

### 依存関係

- 上位レイヤーは下位レイヤーに依存できる（Controller → Service → Model）
- 下位レイヤーは上位レイヤーに依存しない（Model → Controller は禁止）
- 同一レイヤー内での循環依存を避ける

### テスト構造

- テストファイルはソースファイルと同じディレクトリ構造を維持
- FactoryBotのファクトリー定義は`spec/factories/`に集約
- テストヘルパーは`spec/support/`に配置
