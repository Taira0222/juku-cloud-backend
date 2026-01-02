# Code Review Skill - Detailed Guidelines

## 目的と原則

このスキルは、Juku Cloud Backendプロジェクトで実践されている**SDD（仕様駆動開発）**ワークフローに統合されたコードレビューを実施します。

### 基本原則

1. **仕様ファーストの思想**
   - 実装前に`.steering/*/design.md`で仕様を定義
   - コードレビューでは「仕様通りに実装されているか」を最優先で確認

2. **段階的レビュー**
   - 仕様レビュー（design.mdのみのPR）→ 承認後に実装開始
   - 実装レビュー（このスキルを使用）→ 仕様との整合性を重点チェック

3. **自動ツールとの共存**
   - RuboCop: コードスタイル自動チェック
   - Brakeman: セキュリティ脆弱性自動スキャン
   - SimpleCov: カバレッジ自動計測
   - Bullet: N+1クエリ自動検出
   - **このスキル**: 上記で検出できない設計レベルの問題を発見

---

## 重大度（Severity）の判断基準

### Critical: マージ前に必ず修正

以下のいずれかに該当する場合、Criticalと判定：

- **SDD仕様書違反**
  - APIエンドポイント・パラメータがdesign.mdと不一致
  - データモデル（カラム・型・インデックス）がdesign.mdと不一致
  - ビジネスルール（BR-XXX）が未実装
  - 必須テストケース（TC-XXX）が未実装

- **セキュリティ問題**
  - 認証チェック欠如（authenticate_user!未使用）
  - 認可チェック欠如（require_admin_role!未使用）
  - Strong Parameters未使用
  - 機密情報のハードコーディング
  - SQLインジェクションリスク

- **致命的なバグの可能性**
  - トランザクション未使用（複数DB操作時）
  - 例外ハンドリング欠如（重要な処理）

**例（Critical）:**

```ruby
# ❌ Critical: 認証チェックなし
class Api::V1::ReportsController < ApplicationController
  def create
    # authenticate_user! がない
    report = Report.create!(report_params)
    render json: report
  end
end

# ✅ Good: 認証チェックあり
class Api::V1::ReportsController < ApplicationController
  before_action :authenticate_user!

  def create
    report = Report.create!(report_params)
    render json: report
  end
end
```

---

### Warning: 対処すべき

以下のいずれかに該当する場合、Warningと判定：

- **コードスタイル違反（RuboCop以上）**
  - Fat Controller（ビジネスロジックがControllerに記述）
  - Fat Model（複雑な処理がModelに記述）
  - マジックナンバー（定数化されていない数値）

- **パフォーマンス問題**
  - N+1クエリ（includes, preload, eager_load未使用）
  - 不要なデータ取得（select未使用）

- **テスト品質**
  - エッジケーステスト欠如
  - AAAパターン非遵守
  - design.mdに記載のないテストケース欠如

**例（Warning）:**

```ruby
# ⚠️ Warning: Fat Controller（ビジネスロジックがControllerに）
class Api::V1::StudentsController < ApplicationController
  def create
    student = Student.new(student_params)
    student.school_stage = params[:school_stage]
    student.grade = params[:grade]

    # ビジネスロジックがControllerに記述されている
    if student.school_stage == "elementary_school" && student.grade > 6
      render json: { error: "Invalid grade for elementary school" }, status: :unprocessable_entity
      return
    end

    student.save!
    render json: student
  end
end

# ✅ Good: Serviceに分離
class Api::V1::StudentsController < ApplicationController
  def create
    result = Students::CreateService.call(@school, student_params)
    render json: result, status: :created
  end
end

# app/services/students/create_service.rb
class Students::CreateService
  def self.call(school, params)
    student = school.students.new(params)
    validate_grade_for_stage!(student)  # ビジネスロジック
    student.save!
    student
  end

  private

  def self.validate_grade_for_stage!(student)
    # バリデーションロジック
  end
end
```

---

### Info: 推奨

以下のいずれかに該当する場合、Infoと判定：

- **ドキュメント改善**
  - 複雑なロジックへのコメント追加推奨
  - RDocコメント追加推奨

- **リファクタリング機会**
  - 重複コードの抽出
  - より適切な命名

- **パフォーマンス最適化**
  - キャッシュ活用（将来実装予定）
  - インデックス追加検討

**例（Info）:**

```ruby
# ℹ️ Info: 複雑なロジックにコメント追加推奨
def calculate_tuition
  base = 10000
  discount = base * 0.1 if sibling_discount?
  base - discount.to_i
end

# ✅ Good: コメント追加
def calculate_tuition
  base = 10000
  # 兄弟割引: 10%引き
  discount = base * 0.1 if sibling_discount?
  base - discount.to_i
end
```

---

## チェックリストの使用方法

### 1. SDD仕様書整合性チェック

**参照**: `checklists/sdd-consistency.md`

#### 使用タイミング
- `.steering/*/design.md`が存在する場合のみ

#### チェックポイント

**API仕様（API-001〜003）:**
```markdown
design.md:
### POST /api/v1/reports
#### Request
```json
{ "student_id": 123, "year_month": "2025-01" }
```

controller:
def create
  report = Reports::GenerateService.call(
    student_id: params[:student_id],
    year_month: params[:year_month]
  )
end

→ ✅ パラメータ名が一致
```

**データモデル（DM-001〜003）:**
```markdown
design.md:
| カラム | 型 | 制約 |
|--------|-----|------|
| token_digest | string | UNIQUE |

migration:
t.string :token_digest
add_index :invites, :token_digest, unique: true

→ ✅ カラム・インデックスが一致
```

**ビジネスルール（BR-001〜002）:**
```markdown
design.md:
BR-002: 同一月のレポートは1日1回まで生成可能

service:
def self.call(student_id:, year_month:)
  validate_daily_limit!(student_id, year_month)
  # ...
end

→ ✅ BR-002が実装されている
```

---

### 2. コーディング規約チェック

**参照**: `checklists/coding-standards.md`

#### レイヤー構造のGood/Bad例

**LAYER-001: Controllerが薄い**

```ruby
# ❌ Bad: Controllerにビジネスロジック
class Api::V1::InvitesController < ApplicationController
  def create
    raw_token = SecureRandom.urlsafe_base64(32)
    digest = OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, raw_token)
    invite = Invite.create!(token_digest: digest, school: @school)
    render json: { token: raw_token }, status: :created
  end
end

# ✅ Good: Serviceに分離
class Api::V1::InvitesController < ApplicationController
  def create
    result = Invites::TokenGenerate.call(@school)
    render json: { token: result }, status: :created
  end
end
```

**LAYER-004: ModelがThin**

```ruby
# ❌ Bad: Modelに複雑なビジネスロジック
class Student < ApplicationRecord
  def calculate_monthly_fee
    base = 10000
    discount = 0

    if sibling_students.any?
      discount += base * 0.1
    end

    if lessons_this_month > 20
      discount += base * 0.05
    end

    base - discount
  end
end

# ✅ Good: Serviceに移動
class Student < ApplicationRecord
  # Modelにはvalidationsとassociationsのみ
  validates :name, presence: true
  belongs_to :school
  has_many :lesson_notes
end

# app/services/students/calculate_fee_service.rb
class Students::CalculateFeeService
  def self.call(student)
    # ビジネスロジック
  end
end
```

**命名規則のGood/Bad例**

```ruby
# ❌ Bad: 命名規則違反
class StudentController  # クラス名: Student（単数形）→ Students（複数形）が正しい
  def CreateStudent  # メソッド名: PascalCase → snake_case が正しい
    MAX_students = 100  # 定数: camelCase → UPPER_SNAKE_CASE が正しい
  end

  def active  # 真偽値メソッド: ? がない
    status == "active"
  end
end

# ✅ Good: 命名規則遵守
class StudentsController
  def create_student
    MAX_STUDENTS = 100
  end

  def active?
    status == "active"
  end
end
```

---

### 3. セキュリティレビュー

**参照**: `checklists/security.md`

#### 認証・認可のGood/Bad例

```ruby
# ❌ Bad: 認証なし
class Api::V1::StudentsController < ApplicationController
  def index
    students = Student.all
    render json: students
  end
end

# ✅ Good: 認証あり
class Api::V1::StudentsController < ApplicationController
  before_action :authenticate_user!

  def index
    students = @school.students  # @schoolはauthenticate_user!で設定される
    render json: students
  end
end
```

```ruby
# ❌ Bad: 認可なし（他のSchoolの生徒を取得できる）
class Api::V1::StudentsController < ApplicationController
  before_action :authenticate_user!

  def show
    student = Student.find(params[:id])  # 任意のschoolの生徒を取得可能
    render json: student
  end
end

# ✅ Good: 認可あり（自分のSchoolの生徒のみ）
class Api::V1::StudentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_school!

  def show
    student = @school.students.find(params[:id])  # @schoolにスコープされている
    render json: student
  end
end
```

#### Strong ParametersのGood/Bad例

```ruby
# ❌ Bad: Strong Parameters未使用
class Api::V1::StudentsController < ApplicationController
  def create
    student = Student.create!(params[:student])  # 危険！
    render json: student
  end
end

# ❌ Bad: permit!使用（ホワイトリスト方式でない）
def student_params
  params.require(:student).permit!  # 全パラメータ許可（危険）
end

# ✅ Good: Strong Parameters使用（ホワイトリスト方式）
def student_params
  params.require(:student).permit(:name, :school_stage, :grade, :joined_on, :status)
end
```

---

### 4. テスト品質チェック

**参照**: `checklists/testing.md`

#### AAAパターンのGood/Bad例

```ruby
# ❌ Bad: AAAパターン非遵守
it "creates an invite token" do
  post_with_auth api_v1_invites_path, admin_user
  expect(response).to have_http_status(:created)
  expect(json[:token]).to be_present
  invite = Invite.last
  expect(invite.school_id).to eq(admin_user.school_id)
end

# ✅ Good: AAAパターン遵守
it "creates an invite token" do
  # Arrange（準備）
  admin_user = create(:admin_user)

  # Act（実行）
  post_with_auth api_v1_invites_path, admin_user

  # Assert（検証）
  expect(response).to have_http_status(:created)
  expect(json[:token]).to be_present

  invite = Invite.last
  expect(invite.school_id).to eq(admin_user.school_id)
end
```

#### カバレッジのGood/Bad例

```ruby
# ❌ Bad: 正常系のみ（エッジケースなし）
describe "POST /create" do
  it "creates a student" do
    post_with_auth api_v1_school_students_path, admin_user, params: { student: attributes }
    expect(response).to have_http_status(:created)
  end
end

# ✅ Good: 正常系・異常系・エッジケースを網羅
describe "POST /create" do
  context "when valid params" do
    it "creates a student" do
      post_with_auth api_v1_school_students_path, admin_user, params: { student: attributes }
      expect(response).to have_http_status(:created)
    end
  end

  context "when invalid params" do
    it "returns error for missing name" do
      post_with_auth api_v1_school_students_path, admin_user, params: { student: attributes.merge(name: nil) }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context "when invalid grade for stage" do
    it "returns error for grade 7 in elementary school" do
      post_with_auth api_v1_school_students_path, admin_user, params: { student: attributes.merge(school_stage: "elementary_school", grade: 7) }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context "when not authenticated" do
    it "returns unauthorized" do
      post api_v1_school_students_path, params: { student: attributes }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
```

---

## レビュープロセスのベストプラクティス

### 1. 仕様書を最優先で確認

実装レビューの前に、まず`.steering/*/design.md`の存在を確認：

- **存在する場合**: 仕様書を詳細に読み込み、実装との整合性を最優先でチェック
- **存在しない場合**: コーディング規約・セキュリティ・テストのみレビュー

### 2. 重大度の順でレビュー

Critical → Warning → Info の順でレビューし、Criticalが多い場合は即座に指摘：

```
Critical: 3件
⚠️ マージ前に必ず修正が必要です

Warning: 10件
→ Criticalを修正後、Warningに取り組んでください
```

### 3. コンテキストを提供

問題を指摘する際は、必ず以下を含める：

- **ファイルパス・行番号**
- **現在の実装**（コードスニペット）
- **期待される実装**（Good例）
- **理由**（なぜ問題なのか）
- **参照先**（design.md, development-guidelines.mdの該当箇所）

### 4. 自動ツールとの連携

レビュー後、必ず以下のツールを実行するよう推奨：

```bash
# RuboCop（スタイルチェック）
bundle exec rubocop

# Brakeman（セキュリティスキャン）
bundle exec brakeman

# RSpec + カバレッジ
COVERAGE=true bundle exec rspec
# 目標: Line 90%以上、Branch 80%以上

# Bullet（開発環境でN+1クエリ検出）
# 開発サーバーログを確認
```

---

## よくある問題と対処法

### 問題1: N+1クエリ

```ruby
# ❌ Bad: N+1発生
students = school.students.all
students.each do |student|
  puts student.class_subjects.count  # N+1
end

# ✅ Good: includes使用
students = school.students.includes(:class_subjects)
students.each do |student|
  puts student.class_subjects.count
end
```

### 問題2: マジックナンバー

```ruby
# ❌ Bad: マジックナンバー
if lessons.count < 3
  raise "Insufficient lessons"
end

# ✅ Good: 定数化
MINIMUM_LESSONS_FOR_REPORT = 3

if lessons.count < MINIMUM_LESSONS_FOR_REPORT
  raise "Insufficient lessons"
end
```

### 問題3: Fat Controller

```ruby
# ❌ Bad: Controllerにビジネスロジック
class ReportsController < ApplicationController
  def create
    student = Student.find(params[:student_id])
    lessons = student.lesson_notes.where(created_at: ...)

    # ビジネスロジックがControllerに
    if lessons.count < 3
      render json: { error: "..." }, status: :unprocessable_entity
      return
    end

    report = Report.create!(...)
    render json: report
  end
end

# ✅ Good: Serviceに分離
class ReportsController < ApplicationController
  def create
    result = Reports::GenerateService.call(params[:student_id], params[:year_month])
    render json: result, status: :created
  end
end
```

---

## 品質チェックリスト

レビュー完了時、以下を確認：

- [ ] SDD仕様書（design.md）との整合性を確認（存在する場合）
- [ ] レイヤーアーキテクチャが遵守されている
- [ ] 命名規則が統一されている
- [ ] 認証・認可が適切に実装されている
- [ ] Strong Parametersが使用されている
- [ ] 機密情報がハードコーディングされていない
- [ ] テストファイルが存在する
- [ ] テストが正常系・異常系・エッジケースを網羅している
- [ ] N+1クエリが発生していない
- [ ] マジックナンバー・ハードコーディングがない

---

## まとめ

このスキルは、SDD（仕様駆動開発）ワークフローにおける**実装レビュー**の品質を保証します。

**重要なポイント:**
1. 仕様書（design.md）との整合性を最優先でチェック
2. 自動ツール（RuboCop, Brakeman等）では検出できない設計レベルの問題を発見
3. 重大度（Critical/Warning/Info）により優先順位を明確化
4. レビュー結果は具体的かつ実行可能な推奨対応を含める

これにより、コードレビューの効率化と品質向上を同時に実現します。
