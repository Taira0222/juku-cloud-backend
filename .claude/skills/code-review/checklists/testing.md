# Testing Quality Checklist

このチェックリストは、`docs/development-guidelines.md`のテストセクションに基づくテスト品質を検証するためのルール集です。

**参照**: `/app/juku-cloud-backend/docs/development-guidelines.md` (Test section)

**カバレッジ目標**: Line 90%以上、Branch 80%以上（現在: Line 98%, Branch 89%）

---

## Test File Existence

### Rule: TEST-001
**Description**: 変更ファイルに対応するテストファイルが存在すること
**Check**:
- `app/models/student.rb` → `spec/models/student_spec.rb`
- `app/services/students/create_service.rb` → `spec/services/students/create_service_spec.rb`
- `app/controllers/api/v1/students_controller.rb` → `spec/requests/api/v1/students_spec.rb`
- `app/queries/students/index_query.rb` → `spec/queries/students/index_query_spec.rb`
**Severity**: Warning
**Note**: 既存ファイルの軽微な修正の場合は、新規テスト追加は不要な場合もあります

---

## Test Coverage

### Rule: TEST-002
**Description**: カバレッジ目標を達成していること
**Check**:
- Line Coverage: 90%以上
- Branch Coverage: 80%以上
**Severity**: Warning
**Note**: `COVERAGE=true bundle exec rspec`で計測

---

## Test Format

### Rule: TEST-003
**Description**: RSpec形式（describe, context, it）が使用されていること
**Check**:
- `RSpec.describe`でテストブロックが開始されているか
- `describe`でメソッド・機能を説明しているか
- `context`で条件を説明しているか
- `it`で期待動作を説明しているか
**Severity**: Warning
**Good Example**:
```ruby
RSpec.describe Students::CreateService do
  describe ".call" do
    context "when valid params" do
      it "creates a student" do
        # ...
      end
    end

    context "when invalid params" do
      it "raises validation error" do
        # ...
      end
    end
  end
end
```

---

### Rule: TEST-004
**Description**: AAAパターン（Arrange, Act, Assert）が遵守されていること
**Check**:
- テストが3つのセクション（Arrange, Act, Assert）に分かれているか
- セクションの順序が正しいか
**Severity**: Info
**Good Example**:
```ruby
it "creates a student" do
  # Arrange（準備）
  school = create(:school)
  params = { name: "Alice", school_stage: "elementary_school", grade: 1 }

  # Act（実行）
  result = Students::CreateService.call(school, params)

  # Assert（検証）
  expect(result).to be_persisted
  expect(result.name).to eq("Alice")
end
```
**Bad Example**:
```ruby
it "creates a student" do
  school = create(:school)
  result = Students::CreateService.call(school, { name: "Alice", ... })
  expect(result).to be_persisted
  student = Student.last
  expect(student.name).to eq("Alice")
  expect(student.school_id).to eq(school.id)
end
```

---

### Rule: TEST-005
**Description**: FactoryBotが使用されていること
**Check**:
- テストデータがFactoryBotで生成されているか
- `create`, `build`, `build_stubbed`が使用されているか
**Severity**: Info
**Good Example**:
```ruby
let(:student) { create(:student) }
let(:admin_user) { create(:admin_user) }
```
**Bad Example**:
```ruby
let(:student) { Student.create!(name: "Alice", school_stage: 0, ...) }
```

---

## Model Tests

### Rule: TEST-006
**Description**: Modelテスト（validations, associations, scopes）が存在すること
**Check**:
- **Validations**: presence, uniqueness, format, length等のテスト
- **Associations**: belongs_to, has_many, has_one等のテスト
- **Scopes**: カスタムスコープのテスト
- **Custom Methods**: カスタムメソッドのテスト
**Severity**: Warning
**Good Example**:
```ruby
RSpec.describe Student, type: :model do
  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:school_stage) }
  end

  describe "associations" do
    it { should belong_to(:school) }
    it { should have_many(:lesson_notes) }
  end

  describe "custom validations" do
    context "when grade is invalid for stage" do
      it "raises validation error" do
        student = build(:student, school_stage: "elementary_school", grade: 7)
        expect(student).not_to be_valid
        expect(student.errors[:grade]).to include("must be valid for stage")
      end
    end
  end
end
```

---

## Service Tests

### Rule: TEST-007
**Description**: Serviceテスト（正常系、異常系、エッジケース）が存在すること
**Check**:
- **正常系**: 期待通りの動作を検証
- **異常系**: エラー時の動作を検証
- **エッジケース**: 境界値・特殊条件での動作を検証
**Severity**: Warning
**Good Example**:
```ruby
RSpec.describe Students::CreateService do
  describe ".call" do
    context "when valid params" do
      it "creates a student" do
        # 正常系
      end
    end

    context "when invalid params" do
      it "raises validation error" do
        # 異常系
      end
    end

    context "when grade is 0" do
      it "raises validation error" do
        # エッジケース（境界値）
      end
    end

    context "when name is empty string" do
      it "raises validation error" do
        # エッジケース（空文字列）
      end
    end
  end
end
```

---

### Rule: TEST-008
**Description**: トランザクション処理のテストが存在すること
**Check**:
- 複数DBoperationを含むServiceで、ロールバックが正しく動作するかテストされているか
**Severity**: Warning
**Good Example**:
```ruby
context "when student creation fails" do
  it "rolls back all changes" do
    allow_any_instance_of(Student).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)

    expect {
      Students::CreateService.call(school, params)
    }.to raise_error(ActiveRecord::RecordInvalid)
      .and change { Student.count }.by(0)
      .and change { ClassSubject.count }.by(0)
  end
end
```

---

## Request Tests (Integration Tests)

### Rule: TEST-009
**Description**: リクエストテスト（成功ケース、エラーケース、認証・認可）が存在すること
**Check**:
- **成功ケース**: 200, 201, 204等のステータスコードテスト
- **エラーケース**: 400, 401, 403, 404, 422等のステータスコードテスト
- **認証**: `authenticate_user!`のテスト
- **認可**: `require_admin_role!`のテスト
- **レスポンス形式**: JSONレスポンスの構造テスト
**Severity**: Warning
**Good Example**:
```ruby
RSpec.describe "Api::V1::Students", type: :request do
  describe "GET /index" do
    context "when authenticated" do
      it "returns students" do
        get_with_auth api_v1_school_students_path, admin_user
        expect(response).to have_http_status(:ok)
        expect(json[:data]).to be_an(Array)
      end
    end

    context "when not authenticated" do
      it "returns unauthorized" do
        get api_v1_school_students_path
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /create" do
    context "when valid params" do
      it "creates a student" do
        post_with_auth api_v1_school_students_path, admin_user, params: { student: attributes }
        expect(response).to have_http_status(:created)
      end
    end

    context "when invalid params" do
      it "returns unprocessable entity" do
        post_with_auth api_v1_school_students_path, admin_user, params: { student: { name: nil } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when user is teacher (not admin)" do
      it "returns forbidden" do
        teacher_user = create(:teacher_user)
        post_with_auth api_v1_school_students_path, teacher_user, params: { student: attributes }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
```

---

## Query Tests

### Rule: TEST-010
**Description**: N+1問題回避のテストが存在すること
**Check**:
- `includes`, `preload`, `eager_load`使用時、N+1が発生しないかテスト
- `Bullet`gem使用時、警告が出ないかテスト
**Severity**: Warning
**Good Example**:
```ruby
RSpec.describe Students::IndexQuery do
  describe ".call" do
    it "avoids N+1 queries" do
      create_list(:student, 3, :with_class_subjects)

      expect {
        students = Students::IndexQuery.call(school, {})
        students.each do |student|
          student.class_subjects.count  # N+1発生しない
        end
      }.to_not exceed_query_limit(3)
    end
  end
end
```

---

### Rule: TEST-011
**Description**: フィルター・ソート条件のテストが存在すること
**Check**:
- 検索条件（search_keyword, school_stage, grade等）が正しく動作するかテスト
- ソート条件が正しく動作するかテスト
**Severity**: Info
**Good Example**:
```ruby
context "when search_keyword is provided" do
  it "filters students by name" do
    alice = create(:student, name: "Alice")
    bob = create(:student, name: "Bob")

    result = Students::IndexQuery.call(school, { search_keyword: "Ali" })
    expect(result).to include(alice)
    expect(result).not_to include(bob)
  end
end
```

---

## Edge Case Coverage

### Rule: TEST-012
**Description**: エッジケーステストが存在すること
**Check**:
- **境界値**: 0, 1, 最大値等
- **nil/空**: nil, 空文字列, 空配列等
- **特殊文字**: 全角・半角・記号等
**Severity**: Warning
**Good Example**:
```ruby
context "when grade is 0" do
  it "raises validation error" do
    student = build(:student, grade: 0)
    expect(student).not_to be_valid
  end
end

context "when name is empty string" do
  it "raises validation error" do
    student = build(:student, name: "")
    expect(student).not_to be_valid
  end
end

context "when name is nil" do
  it "raises validation error" do
    student = build(:student, name: nil)
    expect(student).not_to be_valid
  end
end
```

---

## Test Independence

### Rule: TEST-013
**Description**: テストが独立していること
**Check**:
- テストが他のテストに依存していないか
- テストの実行順序を変更しても成功するか
**Severity**: Warning
**Good Practice**:
- `let!`の使用を最小限に（遅延評価の`let`を優先）
- テストごとにデータをリセット（FactoryBot + database_cleaner）
- グローバル状態を変更しない

---

## Test Naming

### Rule: TEST-014
**Description**: テスト名が明確であること
**Check**:
- `describe`でメソッド名・機能名が明示されているか
- `context`で条件が`when`で始まっているか
- `it`で期待動作が明確に記述されているか
**Severity**: Info
**Good Example**:
```ruby
describe ".call" do  # メソッド名明示
  context "when valid params" do  # 条件を "when" で開始
    it "creates a student" do  # 期待動作を明確に記述
      # ...
    end
  end
end
```
**Bad Example**:
```ruby
describe "test" do
  context "ok" do
    it "works" do
      # ...
    end
  end
end
```

---

## Test Data Quality

### Rule: TEST-015
**Description**: テストデータが意味のある値であること
**Check**:
- テストデータが実際のユースケースを反映しているか
- `test`, `foo`, `bar`等の意味のない値が使用されていないか
**Severity**: Info
**Good Example**:
```ruby
let(:student) { create(:student, name: "Alice Johnson", grade: 3) }
```
**Bad Example**:
```ruby
let(:student) { create(:student, name: "test", grade: 999) }
```

---

## Summary

このチェックリストにより、以下が保証されます：

1. **テストファイル存在**: 全ファイルに対応するテストが存在
2. **カバレッジ目標達成**: Line 90%以上、Branch 80%以上
3. **テスト形式統一**: RSpec形式（describe, context, it）、AAAパターン
4. **モデルテスト**: validations, associations, scopesの網羅
5. **サービステスト**: 正常系・異常系・エッジケースの網羅
6. **リクエストテスト**: 成功ケース・エラーケース・認証・認可の網羅
7. **N+1問題回避**: Queryテストでincludes使用確認
8. **エッジケース**: 境界値・nil・空文字列のテスト
9. **テスト独立性**: 実行順序に依存しない

**重要**: テストは実装の品質保証だけでなく、仕様書（design.md）との整合性を検証するための重要な手段です。
