# SDD Specification Consistency Checklist

このチェックリストは、`.steering/[date]-[feature]/design.md`（仕様書）と実装コードの整合性を検証するためのルール集です。

**使用タイミング**: `.steering/*/design.md`が存在する場合のみ

---

## API Endpoint Validation

### Rule: API-001
**Description**: APIエンドポイントがdesign.md仕様と一致すること
**Check**:
- design.mdの「API仕様」セクションからエンドポイントを抽出（例: `POST /api/v1/reports`）
- Controller/Routesファイルでエンドポイント定義を確認
- HTTPメソッド（GET, POST, PUT, DELETE等）の一致確認
**Severity**: Critical
**Example Violation**:
```
design.md:    POST /api/v1/reports
controller:   POST /api/v1/report
→ 複数形の's'が欠落
```

---

### Rule: API-002
**Description**: リクエストパラメータ構造がdesign.md仕様と一致すること
**Check**:
- design.mdの「API仕様 > Request」セクションからパラメータリストを抽出
- ControllerのStrong Parametersと比較
- パラメータ名・型・必須/任意の一致確認
**Severity**: Critical
**Example Violation**:
```markdown
# design.md
Request:
{
  "student_id": 123,
  "year_month": "2025-01"
}

# controller (Strong Parameters)
def report_params
  params.require(:report).permit(:student, :month)  # 名前が異なる
end

→ student_id → student, year_month → month に変わっている
```

---

### Rule: API-003
**Description**: レスポンス構造がdesign.md仕様と一致すること
**Check**:
- design.mdの「API仕様 > Response」セクションからレスポンス構造を抽出
- Serializer（Albaリソース）のattributesと比較
- フィールド名・ネスト構造の一致確認
**Severity**: Critical
**Example Violation**:
```markdown
# design.md
Response (201 Created):
{
  "report_url": "https://...",
  "generated_at": "2025-01-31T10:00:00Z"
}

# serializer
class Reports::ShowResource
  attributes :url, :created_at  # 名前が異なる
end

→ report_url → url, generated_at → created_at に変わっている
```

---

### Rule: API-004
**Description**: HTTPステータスコードがdesign.md仕様と一致すること
**Check**:
- design.mdの「API仕様 > Response」セクションからステータスコードを抽出
- Controller内の`render`文のステータスコードと比較
**Severity**: Critical
**Example Violation**:
```markdown
# design.md
Response (201 Created):

# controller
render json: report, status: :ok  # 200 OK
→ 201 Created が期待されるが、200 OK を返している
```

---

## Data Model Validation

### Rule: DM-001
**Description**: Migrationのカラム定義がdesign.mdのテーブル定義と一致すること
**Check**:
- design.mdの「データモデル」セクションからテーブル定義を抽出
- Migrationファイルの`create_table`/`change_table`と比較
- カラム名・型・制約（NOT NULL, DEFAULT等）の一致確認
**Severity**: Critical
**Example Violation**:
```markdown
# design.md
| カラム | 型 | 必須 | デフォルト |
|--------|-----|------|-----------|
| token_digest | string | ○ | - |
| expires_at | datetime | ○ | - |

# migration
create_table :invites do |t|
  t.string :token  # token_digest ではない
  t.datetime :expire_at  # expires_at ではない
end

→ カラム名が不一致
```

---

### Rule: DM-002
**Description**: Modelのアソシエーションがdesign.mdのリレーション定義と一致すること
**Check**:
- design.mdの「データモデル > リレーション」セクションから関連定義を抽出
- Modelファイルの`belongs_to`, `has_many`, `has_one`と比較
**Severity**: Warning
**Example Violation**:
```markdown
# design.md
- Invite belongs_to School
- Invite has_one User

# app/models/invite.rb
class Invite < ApplicationRecord
  belongs_to :school
  # has_one :user が欠落
end

→ has_one :user が未定義
```

---

### Rule: DM-003
**Description**: インデックスがdesign.mdで指定通りに作成されていること
**Check**:
- design.mdの「データモデル > インデックス」セクションからインデックスリストを抽出
- Migrationファイルの`add_index`と比較
- UNIQUE制約の一致確認
**Severity**: Critical
**Example Violation**:
```markdown
# design.md
インデックス:
- token_digest (UNIQUE)
- school_id

# migration
create_table :invites do |t|
  t.string :token_digest
  t.references :school, foreign_key: true
end
# インデックスが欠落

→ add_index :invites, :token_digest, unique: true が必要
```

---

## Business Rules Validation

### Rule: BR-001
**Description**: ビジネスルール（BR-XXX）がService/Modelに実装されていること
**Check**:
- design.mdの「ビジネスルール」セクションから全BR-XXXを抽出
- 各ルールに対応するService/Modelの実装を確認
**Severity**: Critical
**Example Violation**:
```markdown
# design.md
## ビジネスルール
### BR-002: トークン有効期限チェック
- ルール: トークンは7日間有効
- 実装: Invite.expired?メソッドで判定

# app/models/invite.rb
class Invite < ApplicationRecord
  # expired?メソッドが欠落
end

→ BR-002の実装が存在しない
```

---

### Rule: BR-002
**Description**: バリデーションロジックがdesign.md仕様と一致すること
**Check**:
- design.mdの「ビジネスルール」セクションからバリデーション要件を抽出
- Modelファイルの`validates`と比較
**Severity**: Critical
**Example Violation**:
```markdown
# design.md
BR-005: 学年は学校種別に応じて有効範囲内であること
- elementary_school: 1-6
- junior_high_school: 1-3
- high_school: 1-3

# app/models/student.rb
class Student < ApplicationRecord
  validates :grade, presence: true
  # カスタムバリデーションが欠落
end

→ grade_must_be_valid_for_stage バリデーションが必要
```

---

## Test Coverage Validation

### Rule: TC-001
**Description**: テストケース（TC-XXX）がspecファイルに実装されていること
**Check**:
- design.mdの「テスト戦略 > テストケース」セクションから全TC-XXXを抽出
- 対応するspecファイルで各テストケースの存在を確認
**Severity**: Warning
**Example Violation**:
```markdown
# design.md
#### TC-003: 過去3ヶ月以前のレポート生成を試みる
- 入力: 4ヶ月前の year_month
- 期待結果: 422 Unprocessable Entity

# spec/services/reports/generate_service_spec.rb
describe Reports::GenerateService do
  # TC-003に対応するテストが存在しない
end

→ TC-003のテストケースが未実装
```

---

### Rule: TC-002
**Description**: テストの期待結果がdesign.md仕様と一致すること
**Check**:
- design.mdのテストケースで定義された期待結果（ステータスコード、レスポンス等）を抽出
- specファイルのexpectと比較
**Severity**: Warning
**Example Violation**:
```markdown
# design.md
#### TC-001: 正常にレポート生成
- 期待結果: 201 Created, { "report_url": "...", "generated_at": "..." }

# spec/requests/api/v1/reports_spec.rb
it "creates a report" do
  post_with_auth api_v1_reports_path, admin_user, params: { ... }
  expect(response).to have_http_status(:ok)  # 200 OK（201 Createdではない）
end

→ ステータスコードが不一致
```

---

## Security Requirements Validation

### Rule: SEC-001
**Description**: セキュリティ要件（SEC-XXX）が実装されていること
**Check**:
- design.mdの「セキュリティ要件」セクションから全SEC-XXXを抽出
- 対応する実装（before_action, Strong Parameters等）を確認
**Severity**: Critical
**Example Violation**:
```markdown
# design.md
### SEC-001: 認証必須
- 脅威: 未認証ユーザーによるデータ取得
- 実装: authenticate_user! before_action

# app/controllers/api/v1/reports_controller.rb
class Api::V1::ReportsController < ApplicationController
  # authenticate_user! が欠落
  def index
    reports = Report.all
    render json: reports
  end
end

→ SEC-001の実装が存在しない
```

---

## Performance Requirements Validation

### Rule: PERF-001
**Description**: パフォーマンス要件（PERF-XXX）が実装されていること
**Check**:
- design.mdの「パフォーマンス要件」セクションから全PERF-XXXを抽出
- 対応する実装（N+1回避のincludes、ページネーション等）を確認
**Severity**: Warning
**Example Violation**:
```markdown
# design.md
### PERF-001: N+1クエリ回避
- 目標: StudentsリストにClass Subjects含める場合、includes使用
- 測定方法: Bullet使用

# app/queries/students/index_query.rb
def self.call(school, params)
  school.students.all  # includes(:class_subjects) が欠落
end

→ PERF-001の実装が不完全
```

---

## Implementation References Validation

### Rule: IMPL-001
**Description**: design.mdの「実装の参照」セクションに記載されたファイルが存在すること
**Check**:
- design.mdの「実装の参照」セクションからファイルパスを抽出
- 各ファイルの存在を確認
**Severity**: Warning
**Example Violation**:
```markdown
# design.md
## 実装の参照
| カテゴリ | ファイルパス |
|----------|--------------|
| Controller | app/controllers/api/v1/reports_controller.rb |
| Service | app/services/reports/generate_service.rb |

# 実際のファイル構造
app/services/report_service.rb  # パスが異なる

→ ファイルパスが不一致
```

---

## Summary

このチェックリストにより、以下が保証されます：

1. **API仕様の一貫性**: エンドポイント・パラメータ・レスポンス・ステータスコードが仕様通り
2. **データモデルの一貫性**: テーブル定義・リレーション・インデックスが仕様通り
3. **ビジネスルールの実装完全性**: 全BR-XXXが実装されている
4. **テストケースの網羅性**: 全TC-XXXが実装されている
5. **セキュリティ要件の遵守**: 全SEC-XXXが実装されている
6. **パフォーマンス要件の遵守**: 全PERF-XXXが実装されている

**重要**: このチェックリストは、SDD（仕様駆動開発）における「実装レビュー」の最優先事項です。仕様書との不一致は即座に指摘してください。
