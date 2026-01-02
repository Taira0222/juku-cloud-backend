# Issue Format Template

このテンプレートは、レビューレポートで個別の問題を報告する際の標準フォーマットです。

---

## Standard Issue Format

```markdown
#### [ID]: [Issue Title]
**Severity**: [Critical / Warning / Info]
**File**: `[file_path]`
**Line**: [line_number] or N/A

**Issue**:
[問題の詳細説明]

**Current Implementation**:
```[language]
[現在のコード（問題のあるコード）]
```

**Expected** (if applicable):
[期待される実装や仕様]

**Recommendation**:
[修正方法の具体的な提案]

**Related**: [design.md line XX] or [development-guidelines.md section XX]
```

---

## ID Naming Convention

### Format: `[PREFIX]-[CATEGORY]-[NUMBER]`

**Prefix**:
- `CR-` = Critical
- `WR-` = Warning
- `IF-` = Info

**Category**:
- `SDD` = SDD Specification Consistency
- `CODE` = Coding Standards
- `SEC` = Security
- `TEST` = Testing

**Number**: 001, 002, 003, ...（カテゴリ内で連番）

### Examples:
- `CR-SDD-001` = Critical issue in SDD consistency (#1)
- `WR-CODE-002` = Warning in coding standards (#2)
- `IF-TEST-001` = Info in testing (#1)

---

## Example 1: SDD Specification Violation

```markdown
#### CR-SDD-001: API response field name mismatch
**Severity**: Critical
**File**: `app/serializers/reports/show_resource.rb`
**Line**: 5-7

**Issue**:
design.md specifies the response field as `report_url`, but the serializer uses `url`.

**Current Implementation**:
```ruby
class Reports::ShowResource
  include Alba::Resource
  attributes :url, :created_at  # ❌ "url" instead of "report_url"
end
```

**Expected**:
According to design.md line 142:
```json
{
  "report_url": "https://...",
  "generated_at": "..."
}
```

**Recommendation**:
Rename attributes to match the specification:
```ruby
class Reports::ShowResource
  include Alba::Resource
  attributes :report_url, :generated_at

  attribute :report_url do |report|
    report.url  # Map internal field to spec field name
  end

  attribute :generated_at do |report|
    report.created_at
  end
end
```

**Related**: design.md line 142 (API Specification > Response)
```

---

## Example 2: Security Issue

```markdown
#### CR-SEC-001: Missing authorization check
**Severity**: Critical
**File**: `app/controllers/api/v1/reports_controller.rb`
**Line**: 8-12 (create action)

**Issue**:
The controller does not verify that the user can only access their own school's students. This allows users to generate reports for students in other schools.

**Current Implementation**:
```ruby
def create
  student = Student.find(params[:student_id])  # ❌ No school scoping
  report = Reports::GenerateService.call(student, params[:year_month])
  render json: report, status: :created
end
```

**Security Risk**:
- Unauthorized access: Users can access data from other schools
- Data leakage: Sensitive student information could be exposed
- OWASP A01:2021 - Broken Access Control

**Recommendation**:
Add school scoping and authorization check:
```ruby
class Api::V1::ReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_school!  # Ensure @school is set

  def create
    student = @school.students.find(params[:student_id])  # ✅ Scoped to user's school
    report = Reports::GenerateService.call(student, params[:year_month])
    render json: report, status: :created
  end
end
```

**Related**: development-guidelines.md Security section (SEC-003: Authorization)
```

---

## Example 3: Coding Standard Warning

```markdown
#### WR-CODE-001: N+1 query potential
**Severity**: Warning
**File**: `app/queries/students/index_query.rb`
**Line**: 5-10

**Issue**:
The query does not use `includes` to preload associations, which will cause N+1 queries when accessing `class_subjects`.

**Current Implementation**:
```ruby
def self.call(school, params)
  school.students
    .where("name ILIKE ?", "%#{params[:search_keyword]}%")
    .page(params[:page])
end
```

**Recommendation**:
Add `includes` to preload associations:
```ruby
def self.call(school, params)
  school.students
    .includes(:class_subjects, :teachers)  # ✅ Preload associations
    .where("name ILIKE ?", "%#{params[:search_keyword]}%")
    .page(params[:page])
end
```

Verify with Bullet in development mode:
```bash
# Development server logs should not show N+1 warnings
```

**Related**: development-guidelines.md Performance section (N+1 query prevention)
```

---

## Example 4: Test Quality Issue

```markdown
#### WR-TEST-001: Missing edge case test
**Severity**: Warning
**File**: `spec/services/reports/generate_service_spec.rb`

**Issue**:
The test suite does not cover the edge case where a student has zero lesson notes.

**Current Implementation**:
Only normal case is tested:
```ruby
describe Reports::GenerateService do
  describe ".call" do
    it "generates a report" do
      student = create(:student, :with_lesson_notes)
      result = Reports::GenerateService.call(student, "2025-01")
      expect(result).to be_present
    end
  end
end
```

**Missing Tests**:
- Student with zero lesson notes
- Student with lesson notes but outside date range
- Invalid year_month format

**Recommendation**:
Add edge case tests:
```ruby
describe Reports::GenerateService do
  describe ".call" do
    context "when valid params" do
      it "generates a report" do
        # existing test
      end
    end

    context "when student has no lesson notes" do
      it "raises error or returns empty report" do
        student = create(:student)  # No lesson notes
        expect {
          Reports::GenerateService.call(student, "2025-01")
        }.to raise_error(Reports::InsufficientDataError)
      end
    end

    context "when invalid year_month format" do
      it "raises validation error" do
        student = create(:student, :with_lesson_notes)
        expect {
          Reports::GenerateService.call(student, "invalid")
        }.to raise_error(ArgumentError)
      end
    end
  end
end
```

**Related**: design.md line 203 (Test Strategy > TC-003, TC-004)
```

---

## Example 5: Info-level Suggestion

```markdown
#### IF-CODE-001: Consider extracting magic number to constant
**Severity**: Info
**File**: `app/services/reports/generate_service.rb`
**Line**: 15

**Issue**:
The magic number `3` is used without explanation.

**Current Implementation**:
```ruby
def self.call(student_id, year_month)
  lessons = fetch_lessons(student_id, year_month)
  if lessons.count < 3  # ❌ Magic number
    raise InsufficientLessonsError
  end
  # ...
end
```

**Recommendation**:
Extract to a named constant for clarity:
```ruby
class Reports::GenerateService
  MINIMUM_LESSONS_FOR_REPORT = 3

  def self.call(student_id, year_month)
    lessons = fetch_lessons(student_id, year_month)
    if lessons.count < MINIMUM_LESSONS_FOR_REPORT
      raise InsufficientLessonsError
    end
    # ...
  end
end
```

**Related**: development-guidelines.md Coding Standards (ANTI-003: Magic numbers)
```

---

## Usage Notes

1. **ID uniqueness**: Ensure IDs are unique within a single review report
2. **Severity consistency**: Follow the severity guidelines in guide.md
3. **Code examples**: Always provide code examples for clarity
4. **Related references**: Always link to design.md or development-guidelines.md
5. **Actionable recommendations**: Provide specific, implementable solutions

---

## Template Variables

When generating issues, replace the following variables:

- `[ID]`: Unique issue ID (e.g., CR-SDD-001)
- `[Issue Title]`: Short, descriptive title (max 60 chars)
- `[file_path]`: Absolute path from project root
- `[line_number]`: Line number or range (e.g., 15 or 15-20)
- `[language]`: Code block language (ruby, json, bash, etc.)
- `[問題の詳細説明]`: Detailed explanation of the issue
- `[現在のコード]`: Current implementation (problematic code)
- `[期待される実装や仕様]`: Expected implementation or specification
- `[修正方法の具体的な提案]`: Concrete recommendation with code examples
- `[Related reference]`: Link to design.md line or development-guidelines.md section
