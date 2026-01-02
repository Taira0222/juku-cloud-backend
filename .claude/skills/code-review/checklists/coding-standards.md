# Coding Standards Checklist

このチェックリストは、`docs/development-guidelines.md`に基づくコーディング規約遵守を検証するためのルール集です。

**参照**: `/app/juku-cloud-backend/docs/development-guidelines.md`

---

## Layer Architecture

### Rule: LAYER-001
**Description**: Controllerが薄く、ビジネスロジックが含まれていないこと
**Check**:
- Controller内に複雑な条件分岐・計算ロジックが存在しないか
- ビジネスロジックがServiceに委譲されているか
- Controllerの責務がリクエスト受付・レスポンス返却のみか
**Severity**: Warning
**Good Example**:
```ruby
class Api::V1::StudentsController < ApplicationController
  def create
    result = Students::CreateService.call(@school, student_params)
    render json: result, status: :created
  end
end
```
**Bad Example**:
```ruby
class Api::V1::StudentsController < ApplicationController
  def create
    student = Student.new(student_params)
    if student.school_stage == "elementary_school" && student.grade > 6
      render json: { error: "Invalid grade" }, status: :unprocessable_entity
      return
    end
    student.save!
    render json: student
  end
end
```

---

### Rule: LAYER-002
**Description**: ビジネスロジックがServiceに配置されていること
**Check**:
- 複数モデル操作がServiceに実装されているか
- トランザクション管理がServiceで行われているか
- ビジネスルールの実装がServiceにあるか
**Severity**: Warning
**Good Example**:
```ruby
# app/services/students/create_service.rb
class Students::CreateService
  def self.call(school, params)
    ActiveRecord::Base.transaction do
      student = school.students.create!(params)
      assign_class_subjects(student, params[:class_subject_ids])
      student
    end
  end

  private

  def self.assign_class_subjects(student, subject_ids)
    # ビジネスロジック
  end
end
```

---

### Rule: LAYER-003
**Description**: 複雑なクエリがQueryオブジェクトに分離されていること
**Check**:
- Controller/Serviceに複雑なActiveRecordクエリが直接記述されていないか
- フィルタ・ソート・ページネーションロジックがQueryに分離されているか
- N+1問題回避（includes, preload, eager_load）がQueryで実装されているか
**Severity**: Warning
**Good Example**:
```ruby
# app/queries/students/index_query.rb
class Students::IndexQuery
  def self.call(school, params)
    school.students
      .includes(:class_subjects, :teachers)
      .where("name ILIKE ?", "%#{params[:search_keyword]}%")
      .page(params[:page])
  end
end

# Controller
students = Students::IndexQuery.call(@school, params)
```

---

### Rule: LAYER-004
**Description**: ModelがThin（validationsとassociationsのみ）であること
**Check**:
- Modelに複雑なビジネスロジックが含まれていないか
- Modelの責務がデータ永続化・バリデーション定義に限定されているか
**Severity**: Warning
**Bad Example**:
```ruby
class Student < ApplicationRecord
  def calculate_monthly_fee
    base = 10000
    discount = 0
    discount += base * 0.1 if sibling_students.any?
    discount += base * 0.05 if lessons_this_month > 20
    base - discount
  end
end
```
**Good Example**:
```ruby
# app/models/student.rb
class Student < ApplicationRecord
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

---

### Rule: LAYER-005
**Description**: SerializerでJSON整形が行われていること（Alba使用）
**Check**:
- ControllerでJSON整形ロジック（as_json, to_json等）が直接記述されていないか
- Albaリソースクラスが使用されているか
**Severity**: Info
**Good Example**:
```ruby
# app/serializers/students/index_resource.rb
class Students::IndexResource
  include Alba::Resource
  attributes :id, :name, :school_stage, :grade
end

# Controller
render json: Students::IndexResource.new(students).serialize
```

---

## Naming Conventions

### Rule: NAME-001
**Description**: 変数・メソッド名がsnake_caseであること
**Check**:
- 変数名・メソッド名がsnake_caseで命名されているか
**Severity**: Warning
**Good Example**: `student_id`, `create_service`, `calculate_fee`
**Bad Example**: `studentId`, `CreateService`, `calculateFee`

---

### Rule: NAME-002
**Description**: クラス・モジュール名がPascalCaseであること
**Check**:
- クラス名・モジュール名がPascalCaseで命名されているか
**Severity**: Warning
**Good Example**: `Student`, `Students::CreateService`, `Api::V1::StudentsController`
**Bad Example**: `student`, `students_create_service`, `api_v1_students_controller`

---

### Rule: NAME-003
**Description**: 定数名がUPPER_SNAKE_CASEであること
**Check**:
- 定数名がUPPER_SNAKE_CASEで命名されているか
**Severity**: Warning
**Good Example**: `MAX_STUDENTS`, `DEFAULT_EXPIRES_AT`, `MINIMUM_LESSONS_FOR_REPORT`
**Bad Example**: `MaxStudents`, `defaultExpiresAt`, `minimumLessonsForReport`

---

### Rule: NAME-004
**Description**: 真偽値を返すメソッドが?で終わること
**Check**:
- 真偽値（true/false）を返すメソッドが`?`で終わっているか
**Severity**: Warning
**Good Example**:
```ruby
def active?
  status == "active"
end

def expired?
  expires_at.present? && Time.current > expires_at
end
```
**Bad Example**:
```ruby
def active
  status == "active"
end

def is_expired
  expires_at.present? && Time.current > expires_at
end
```

---

### Rule: NAME-005
**Description**: 破壊的メソッドが!で終わること
**Check**:
- オブジェクトを変更するメソッドが`!`で終わっているか
**Severity**: Warning
**Good Example**:
```ruby
def consume!
  update!(uses_count: uses_count + 1)
end
```
**Bad Example**:
```ruby
def consume
  update!(uses_count: uses_count + 1)  # 破壊的だが!がない
end
```

---

## Anti-Patterns

### Rule: ANTI-001
**Description**: Fat Controllerが存在しないこと
**Check**:
- Controllerに10行以上のビジネスロジックが含まれていないか
- 条件分岐・ループがControllerに直接記述されていないか
**Severity**: Warning
**Indicators**:
- Controllerメソッドが20行以上
- 複数の条件分岐（if/elsif/case）
- ActiveRecordのクエリが複数行

---

### Rule: ANTI-002
**Description**: Fat Modelが存在しないこと
**Check**:
- Modelに50行以上のビジネスロジックメソッドが含まれていないか
- Model内で複雑な計算・外部API呼び出しが行われていないか
**Severity**: Warning
**Indicators**:
- Modelファイルが200行以上
- publicメソッドが10個以上（validations/associations除く）
- 外部サービス呼び出し（HTTPリクエスト等）

---

### Rule: ANTI-003
**Description**: マジックナンバーが存在しないこと
**Check**:
- 定数化されていない数値が使用されていないか
- 定数として抽出すべき数値が直接記述されていないか
**Severity**: Warning
**Bad Example**:
```ruby
if lessons.count < 3
  raise "Insufficient lessons"
end

expires_at = 7.days.from_now
```
**Good Example**:
```ruby
MINIMUM_LESSONS_FOR_REPORT = 3
DEFAULT_EXPIRY_DAYS = 7

if lessons.count < MINIMUM_LESSONS_FOR_REPORT
  raise "Insufficient lessons"
end

expires_at = DEFAULT_EXPIRY_DAYS.days.from_now
```

---

### Rule: ANTI-004
**Description**: ハードコーディングが存在しないこと
**Check**:
- URL・設定値・マジックストリングが直接記述されていないか
- 定数・ENV変数として管理すべき値がハードコーディングされていないか
**Severity**: Warning
**Bad Example**:
```ruby
base_url = "https://example.com/api/v1"
secret_key = "my_secret_key_12345"
```
**Good Example**:
```ruby
base_url = ENV["API_BASE_URL"]
secret_key = Rails.application.credentials.secret_key_base
```

---

### Rule: ANTI-005
**Description**: グローバル変数が使用されていないこと
**Check**:
- `$variable`形式のグローバル変数が使用されていないか
**Severity**: Critical
**Note**: Railsプロジェクトでグローバル変数は使用禁止

---

## Code Style

### Rule: STYLE-001
**Description**: インデントがスペース2つであること
**Check**:
- タブではなくスペース2つでインデントされているか
**Severity**: Info
**Note**: RuboCopで自動検出可能

---

### Rule: STYLE-002
**Description**: 行の長さが120文字以下であること
**Check**:
- 1行が120文字を超えていないか
**Severity**: Info
**Note**: RuboCopで自動検出可能

---

### Rule: STYLE-003
**Description**: 文字列リテラルがダブルクォートであること
**Check**:
- 文字列がダブルクォート`"`で囲まれているか（式展開なしの場合はシングルクォート可）
**Severity**: Info
**Note**: RuboCopで自動検出可能

---

### Rule: STYLE-004
**Description**: ハッシュ記法が新記法（key: value）であること
**Check**:
- シンボルキーのハッシュが新記法で記述されているか
**Severity**: Info
**Good Example**: `{ name: "Alice", age: 25 }`
**Bad Example**: `{ :name => "Alice", :age => 25 }`

---

## Comments

### Rule: COMMENT-001
**Description**: WHYを説明するコメントが記述されていること
**Check**:
- 複雑なロジックに「なぜ」を説明するコメントがあるか
- WHATを説明する不要なコメントが含まれていないか
**Severity**: Info
**Good Example**:
```ruby
# 兄弟割引: 同一Schoolに在籍する兄弟姉妹がいる場合、10%割引
discount += base * 0.1 if sibling_students.any?
```
**Bad Example**:
```ruby
# discountに10%を追加（WHATの説明なので不要）
discount += base * 0.1 if sibling_students.any?
```

---

### Rule: COMMENT-002
**Description**: 公開APIにRDocコメントが記述されていること
**Check**:
- Publicメソッド（Service等）にRDocスタイルのコメントがあるか
**Severity**: Info
**Good Example**:
```ruby
# Generates a secure invitation token for the school
#
# @param school [School] The school to generate token for
# @param role [Symbol] The role for the invited user (:teacher or :admin)
# @return [String] The raw token (not hashed)
def self.call(school, role: :teacher)
  # ...
end
```

---

## Summary

このチェックリストにより、以下が保証されます：

1. **レイヤーアーキテクチャ**: Controller, Service, Query, Model, Serializerの責務が明確
2. **命名規則**: snake_case, PascalCase, UPPER_SNAKE_CASE, ?, !の統一
3. **アンチパターン回避**: Fat Controller, Fat Model, マジックナンバー, ハードコーディング, グローバル変数の排除
4. **コードスタイル**: インデント、行長、文字列リテラル、ハッシュ記法の統一
5. **コメント**: WHYを説明し、RDocで公開API文書化

**Note**: STYLE-001〜004はRuboCopで自動検出可能なため、レビューではWarning扱いとします。RuboCop実行を推奨してください。
