# 用語集

## 概要

このドキュメントは、Juku Cloud Backend プロジェクト内で使用される用語の定義を提供します。チーム内での認識齟齬を防ぎ、一貫性のあるコミュニケーションを実現します。

## ビジネス用語

### School（塾）

**定義:** 塾の組織単位。複数の講師（User）が所属し、生徒（Student）を管理する

**属性:**
- `name`: 塾名
- `created_at`: 作成日時
- `updated_at`: 更新日時

**リレーション:**
- `has_many :users`（講師）
- `has_many :students`（生徒）
- `has_many :invites`（招待トークン）

**使用例:** 「Schoolの管理者は新しい講師を招待できる」

**関連用語:** [User](#user講師), [Student](#student生徒), [Invite](#invite招待トークン)

---

### User（講師）

**定義:** プラットフォーム上で授業を提供し、生徒を指導するユーザー

**Role:**
- `admin`: 管理者（全操作可能、招待トークン生成、削除操作可能）
- `teacher`: 講師（読み取り・作成・更新のみ、削除は不可）

**権限:**
- 自分が担当する授業記録の作成・編集
- 生徒情報の閲覧
- 授業記録の管理（LessonNote）

**使用例:** 「講師は授業記録を作成し、生徒の理解度を記録できる」

**関連用語:** [Student](#student生徒), [LessonNote](#lessonnote授業記録), [School](#school塾)

**コード例:**
```ruby
class User < ApplicationRecord
  belongs_to :school
  has_many :lesson_notes_created, class_name: "LessonNote", foreign_key: :created_by_id

  enum :role, { admin: 0, teacher: 1 }
end
```

---

### Student（生徒）

**定義:** Schoolに所属し、授業記録（LessonNote）の対象となる

**属性:**
- `name`: 生徒名
- `school_stage`: 学校段階（elementary_school / junior_high_school / high_school）
- `grade`: 学年（小学校1-6、中高1-3）
- `joined_on`: 入塾日
- `status`: 状態（active / inactive / on_leave / graduated）
- `desired_school`: 志望校

**リレーション:**
- `belongs_to :school`
- `has_many :lesson_notes`（through student_class_subjects）
- `has_many :class_subjects`（科目）
- `has_many :teachers`（担当講師）

**使用例:** 「生徒は複数の科目を受講し、授業記録が蓄積される」

**関連用語:** [School](#school塾), [LessonNote](#lessonnote授業記録), [ClassSubject](#classsubject科目)

**コード例:**
```ruby
class Student < ApplicationRecord
  belongs_to :school
  has_many :lesson_notes, through: :student_class_subjects

  enum :school_stage, { elementary_school: 0, junior_high_school: 1, high_school: 2 }
  enum :status, { active: 0, inactive: 1, on_leave: 2, graduated: 3 }
end
```

---

### LessonNote（授業記録）

**定義:** 講師が授業完了後に記録する指導内容・理解度・宿題・次回予定

**属性:**
- `title`: タイトル（最大50文字）
- `description`: 説明（最大500文字）
- `note_type`: 種別（homework / lesson / other）
- `expire_date`: 期限日（未来または当日）
- `created_by_id`: 作成者ID
- `created_by_name`: 作成者名（非正規化）
- `last_updated_by_id`: 最終更新者ID
- `last_updated_by_name`: 最終更新者名（非正規化）

**リレーション:**
- `belongs_to :student_class_subject`（生徒・科目の組み合わせ）
- `belongs_to :created_by, class_name: "User"`
- `belongs_to :last_updated_by, class_name: "User", optional: true`

**使用例:** 「講師は授業完了後にLessonNoteを作成し、次回の指導予定を記録する」

**関連用語:** [User](#user講師), [Student](#student生徒), [ClassSubject](#classsubject科目)

**コード例:**
```ruby
class LessonNote < ApplicationRecord
  belongs_to :student_class_subject, class_name: "Subjects::StudentLink"
  belongs_to :created_by, class_name: "User"

  enum :note_type, { homework: 0, lesson: 1, other: 2 }, suffix: true

  validates :title, presence: true, length: { maximum: 50 }
  validates :description, length: { maximum: 500 }
end
```

---

### ClassSubject（科目）

**定義:** 授業記録の分類に使用する科目（数学、英語、国語など）

**属性:**
- `name`: 科目名
- `created_at`: 作成日時
- `updated_at`: 更新日時

**リレーション:**
- `has_many :student_class_subjects`（生徒との関連）
- `has_many :students, through: :student_class_subjects`

**使用例:** 「ClassSubjectを作成し、生徒に科目を割り当てる」

**関連用語:** [Student](#student生徒), [LessonNote](#lessonnote授業記録)

---

### Invite（招待トークン）

**定義:** 管理者が新しい講師を招待するためのセキュアなトークン

**属性:**
- `token_digest`: HMAC-SHA256ハッシュ化されたトークン（UNIQUE）
- `school_id`: 招待元のSchool
- `role`: 招待されるユーザーのrole（デフォルト: teacher）
- `expires_at`: トークンの有効期限（7日後）
- `max_uses`: 最大使用回数（デフォルト: 1）
- `uses_count`: 現在の使用回数
- `used_at`: 最終使用日時

**セキュリティ:**
- 生トークンはDBに保存せず、HMAC-SHA256ハッシュのみ保存
- トークンは`SecureRandom.urlsafe_base64(32)`で生成（256ビットエントロピー）

**使用例:** 「管理者が招待トークンを生成し、新しい講師を安全に招待する」

**関連用語:** [School](#school塾), [User](#user講師)

**コード例:**
```ruby
class Invite < ApplicationRecord
  belongs_to :school
  enum :role, { teacher: 0 }

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true
end
```

---

## 技術用語

### Rails API mode

**定義:** フロントエンドとバックエンドを分離したRailsアプリケーションモード。ビュー層を持たず、JSON APIのみを提供する

**使用例:** 「Juku Cloud BackendはRails API modeで実装されている」

**関連用語:** [RESTful API](#restful-api), [devise_token_auth](#devise_token_auth)

---

### devise_token_auth

**定義:** Rails APIでトークンベース認証を実装するためのgemライブラリ

**認証ヘッダー:**
- `access-token`: アクセストークン
- `client`: クライアントID
- `uid`: ユーザーID（メールアドレス）

**トークン有効期限:** 24時間

**使用例:** 「ユーザー認証にdevise_token_authを使用し、トークンベースのステートレス認証を実現する」

**関連用語:** [認証](#認証-authentication), [JWT](#jwt-json-web-token)

---

### Alba

**定義:** Ruby用の高速JSONシリアライザーライブラリ。このプロジェクトではAPIレスポンスの整形に使用

**命名規則:**
- `*::IndexResource`: 一覧用シリアライザ
- `*::CreateResource`: 作成時レスポンス用
- `*::UpdateResource`: 更新時レスポンス用

**使用例:** 「Students::IndexResourceはAlbaを使用して生徒情報をJSON化する」

**関連用語:** [Serializer](#serializer-シリアライザー)

**コード例:**
```ruby
class Students::IndexResource
  include Alba::Resource

  attributes :id, :name, :school_stage, :grade, :status
  many :class_subjects
  many :teachers
end
```

---

### Kaminari

**定義:** Railsのページネーションgemライブラリ。大量データを分割取得する

**デフォルト設定:**
- 1ページあたり20件
- ページ番号: `page`パラメータ
- 件数指定: `perPage`パラメータ

**使用例:** 「Kaminariを使用して生徒一覧をページネーションする」

**コード例:**
```ruby
students = school.students.page(params[:page]).per(params[:perPage] || 20)
```

---

### Bullet

**定義:** N+1クエリ検出gemライブラリ。開発時に非効率なクエリを警告する

**検出内容:**
- N+1クエリ
- 不要なEager Loading
- 未使用のEager Loading

**使用例:** 「Bulletを有効化してN+1問題を検出する」

**関連用語:** [N+1問題](#n1問題)

---

### Brakeman

**定義:** Railsアプリケーションのセキュリティ脆弱性を静的解析するツール

**検出内容:**
- SQLインジェクション
- XSS（クロスサイトスクリプティング）
- CSRF（クロスサイトリクエストフォージェリ）
- マスアサインメント脆弱性
- 安全でないデシリアライゼーション

**使用例:** 「Brakemanで脆弱性をスキャンする」

```bash
bundle exec brakeman
```

---

### Service層

**定義:** ビジネスロジックを実装するレイヤー。ControllerとModelの間に位置し、複雑な処理を担当

**責務:**
- 複数のモデルにまたがるビジネスロジック
- トランザクション管理
- 外部サービスとの連携
- 非同期ジョブの起動

**命名規則:**
- `*::CreateService`: リソース作成
- `*::Updater`: リソース更新
- `*::Validator`: バリデーション
- `*::TokenGenerate`: トークン生成

**使用例:** 「Students::CreateServiceは生徒作成のビジネスロジックを実装する」

**関連用語:** [レイヤードアーキテクチャ](#レイヤードアーキテクチャ)

**コード例:**
```ruby
module Students
  class CreateService
    def self.call(school:, create_params:)
      student = school.students.build(create_params)
      student.save!
      student
    end
  end
end
```

---

### Query層

**定義:** 複雑なデータベースクエリを実装するレイヤー。N+1問題の回避や動的な検索条件の組み立てを担当

**責務:**
- 複雑なJOINクエリ
- 動的な検索条件の組み立て
- N+1問題の回避（includes、preload、eager_load）
- ページネーション

**命名規則:**
- `*::IndexQuery`: 一覧取得

**使用例:** 「Students::IndexQueryは生徒一覧をフィルタリング・ページネーション付きで取得する」

**関連用語:** [N+1問題](#n1問題), [Kaminari](#kaminari)

**コード例:**
```ruby
module Students
  class IndexQuery
    def self.call(school:, index_params:, current_user:)
      students = school.students
                .includes(:class_subjects, :available_days, :teachers)
                .page(index_params[:page])
                .per(index_params[:perPage] || 20)
      students = students.where(school_stage: index_params[:school_stage]) if index_params[:school_stage].present?
      students
    end
  end
end
```

---

### N+1問題

**定義:** ORMを使用する際に、親レコード取得後に各子レコードを個別に取得することで発生するパフォーマンス問題

**対策:**
- `includes`: 関連を事前読み込み（LEFT OUTER JOIN）
- `preload`: 関連を別クエリで読み込み
- `eager_load`: 関連を強制的にJOINで読み込み

**検出:** Bulletで自動検出

**悪い例:**
```ruby
# N+1問題あり - 生徒数分のクエリが発行される
students = Student.all
students.each { |student| puts student.class_subjects.map(&:name) }
```

**良い例:**
```ruby
# N+1問題なし - 1-2回のクエリで取得
students = Student.includes(:class_subjects).all
students.each { |student| puts student.class_subjects.map(&:name) }
```

**関連用語:** [Bullet](#bullet), [Query層](#query層)

---

### Serializer（シリアライザー）

**定義:** JSONレスポンスを整形するレイヤー。機密情報を除外し、必要な情報のみを返す

**責務:**
- JSONレスポンスの整形
- 機密情報の除外（パスワード、トークン等）
- ネストされたリソースの含め方の制御

**使用例:** 「Students::IndexResourceでSerializerを使用して生徒情報をJSON化する」

**関連用語:** [Alba](#alba)

---

### HMAC-SHA256

**定義:** ハッシュベースのメッセージ認証コード。招待トークンの改ざん防止とDB検索性を両立するために採用

**特徴:**
- 暗号学的に安全
- 決定論的（同じ入力から同じ出力）
- DB検索可能（bcryptは非決定論的で検索不可）

**使用例:** 「招待トークンをHMAC-SHA256でハッシュ化してDBに保存する」

**コード例:**
```ruby
raw_token = SecureRandom.urlsafe_base64(32)
token_digest = OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, raw_token)
```

**関連用語:** [Invite](#invite招待トークン)

---

### ActiveRecord

**定義:** RailsのORM（Object-Relational Mapping）ライブラリ。データベーステーブルをRubyのオブジェクトとして扱う

**機能:**
- マイグレーション管理
- クエリビルダー
- バリデーション
- アソシエーション
- コールバック

**使用例:** 「StudentモデルはActiveRecordを継承している」

**関連用語:** [ORM](#orm-object-relational-mapping)

---

### RSpec

**定義:** Rubyのテストフレームワーク。BDD（振る舞い駆動開発）スタイルでテストを記述

**テスト種類:**
- モデルテスト: バリデーション、メソッドのテスト
- リクエストテスト: APIエンドポイントの統合テスト
- サービステスト: ビジネスロジックのテスト
- クエリテスト: データベースクエリのテスト

**使用例:** 「RSpecでStudentモデルのバリデーションをテストする」

**コード例:**
```ruby
RSpec.describe Student, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:school_stage) }
  end
end
```

---

### FactoryBot

**定義:** RSpecと連携してテストデータを生成するライブラリ

**使用例:**
```ruby
# ファクトリー定義
FactoryBot.define do
  factory :student do
    school
    name { 'John Doe' }
    school_stage { :junior_high_school }
    grade { 2 }
  end
end

# テストで使用
student = create(:student)  # DBに保存
student = build(:student)   # メモリ上のみ
```

**関連用語:** [RSpec](#rspec)

---

### SimpleCov

**定義:** Rubyのコードカバレッジ計測ツール

**計測指標:**
- Line Coverage: 行カバレッジ
- Branch Coverage: 分岐カバレッジ

**目標:**
- Line: 90%以上（現在98%）
- Branch: 80%以上（現在89%）

**使用例:**
```bash
COVERAGE=true bundle exec rspec
open coverage/index.html
```

---

## アーキテクチャ用語

### レイヤードアーキテクチャ

**定義:** システムを複数の層に分割し、各層が特定の責務を持つアーキテクチャパターン

**層構成:**
1. **Controller（コントローラー層）:** リクエスト/レスポンス処理
2. **Service（サービス層）:** ビジネスロジック
3. **Model（モデル層）:** データ永続化
4. **Query（クエリ層）:** 複雑なデータ取得
5. **Serializer（シリアライザー層）:** JSONレスポンス整形

**使用例:** 「レイヤードアーキテクチャに従ってコードを配置する」

**関連用語:** [Service層](#service層), [Query層](#query層)

---

### RESTful API

**定義:** HTTPプロトコルを使用したWebサービスのアーキテクチャスタイル

**HTTPメソッド:**
- `GET`: リソース取得
- `POST`: リソース作成
- `PATCH`: リソース部分更新
- `PUT`: リソース完全更新
- `DELETE`: リソース削除

**ステータスコード:**
- `200 OK`: 成功（GET, PATCH）
- `201 Created`: リソース作成成功（POST）
- `204 No Content`: 削除成功（DELETE）
- `400 Bad Request`: クライアント側エラー
- `401 Unauthorized`: 認証エラー
- `403 Forbidden`: 認可エラー
- `404 Not Found`: リソース不存在
- `422 Unprocessable Entity`: バリデーションエラー
- `500 Internal Server Error`: サーバー側エラー

**使用例:** 「RESTful APIを設計する」

**関連用語:** [API](#api-application-programming-interface)

---

## セキュリティ用語

### 認証（Authentication）

**定義:** ユーザーが本人であることを確認するプロセス

**方式:** devise_token_authによるトークンベース認証

**使用例:** 「メールアドレスとパスワードで認証を行う」

**関連用語:** [認可](#認可-authorization), [devise_token_auth](#devise_token_auth)

---

### 認可（Authorization）

**定義:** 認証されたユーザーが特定のリソースにアクセスする権限を持つかを判断するプロセス

**方式:** Role-Based Access Control（RBAC）
- `admin`: 全操作可能
- `teacher`: 読み取り・作成・更新のみ

**使用例:** 「管理者のみが生徒を削除できるよう認可を設定する」

**関連用語:** [認証](#認証-authentication), [Role](#roleユーザー権限)

---

### CORS（Cross-Origin Resource Sharing）

**定義:** 異なるオリジンからのリソースへのアクセスを制御する仕組み

**設定:** `config/initializers/cors.rb`

**使用例:** 「CORSを設定してフロントエンドからのAPIアクセスを許可する」

**関連用語:** [RESTful API](#restful-api)

---

## インフラ用語

### ECS Fargate

**定義:** AWSのコンテナオーケストレーションサービス。サーバーレスでコンテナを実行

**使用例:** 「ECS FargateでRails APIをデプロイする」

**関連用語:** [Docker](#docker), [ECR](#ecr)

---

### RDS（Amazon Relational Database Service）

**定義:** AWSのマネージドなリレーショナルデータベースサービス

**使用:** PostgreSQL 15（Single-AZ、将来Multi-AZ移行可能）

**機能:**
- 自動バックアップ（7日間保持）
- 自動パッチ適用
- スナップショット取得

**使用例:** 「RDS PostgreSQLでデータベースを管理する」

---

### CloudWatch Logs

**定義:** AWSのログ集約・監視サービス

**使用例:** 「CloudWatch LogsでRailsのログを集約・監視する」

---

## 略語一覧

| 略語 | 正式名称 | 日本語 |
|------|----------|--------|
| API | Application Programming Interface | アプリケーションプログラミングインターフェース |
| REST | Representational State Transfer | レプレゼンテーショナルステートトランスファー |
| ORM | Object-Relational Mapping | オブジェクト関係マッピング |
| CORS | Cross-Origin Resource Sharing | クロスオリジンリソース共有 |
| RBAC | Role-Based Access Control | ロールベースアクセス制御 |
| CRUD | Create, Read, Update, Delete | 作成、読取、更新、削除 |
| TDD | Test-Driven Development | テスト駆動開発 |
| BDD | Behavior-Driven Development | 振る舞い駆動開発 |
| CI/CD | Continuous Integration/Continuous Deployment | 継続的インテグレーション/継続的デプロイメント |
| ECS | Elastic Container Service | エラスティックコンテナサービス |
| RDS | Relational Database Service | リレーショナルデータベースサービス |
| ECR | Elastic Container Registry | エラスティックコンテナレジストリ |
| ALB | Application Load Balancer | アプリケーションロードバランサー |

## 更新履歴

| 日付 | 変更内容 | 更新者 |
|------|----------|--------|
| 2025-12-31 | 初版作成 | Claude Code |
