# Code Review Report

**Reviewed**: [対象説明 - PR, ファイルパス, ディレクトリ等]
**Review Date**: [ISO 8601タイムスタンプ]
**Reviewer**: Claude Code Review Agent

---

## Executive Summary

| Category | Critical | Warning | Info | Total |
|----------|----------|---------|------|-------|
| SDD Consistency | X | X | X | X |
| Coding Standards | X | X | X | X |
| Security | X | X | X | X |
| Testing | X | X | X | X |
| **TOTAL** | **X** | **X** | **X** | **X** |

**Overall Assessment**: [✅ Ready to Merge / ⚠️ Changes Required / ❌ Major Issues]

[簡潔な総評を1-2文で記述]

---

## 1. SDD Specification Consistency Review

**Specification**: [`.steering/[date]-[feature]/design.md` or "N/A - No specification found"]

[仕様書が存在しない場合]
```
No design.md specification found for this change.
Skipping SDD consistency check.
```

[仕様書が存在する場合]

### ✅ Passed Checks

- [チェック項目1]
- [チェック項目2]
- [チェック項目3]

### ❌ Critical Issues

[issue-format.mdのフォーマットを使用して問題を列挙]

#### CR-SDD-001: [Issue Title]
**Severity**: Critical
**File**: `[file_path]`
**Line**: [line_number] or N/A

**Issue**:
[問題の説明]

**Current Implementation**:
```ruby
[現在のコード]
```

**Expected**:
[期待される実装]

**Recommendation**:
[修正方法の提案]

**Related**: [design.md line XX]

---

### ⚠️ Warnings

[同様のフォーマットで Warning を列挙]

---

### ℹ️ Info

[同様のフォーマットで Info を列挙]

---

## 2. Coding Standards Review

### ✅ Passed Checks

- [チェック項目1]
- [チェック項目2]

### ❌ Critical Issues

[issue-format.mdのフォーマットを使用]

---

### ⚠️ Warnings

#### WR-CODE-001: [Issue Title]
**Severity**: Warning
**File**: `[file_path]`
**Line**: [line_number]

**Issue**:
[問題の説明]

**Current Implementation**:
```ruby
[現在のコード]
```

**Recommendation**:
[修正方法の提案]

**Related**: [development-guidelines.md section XX]

---

### ℹ️ Info

[同様のフォーマット]

---

## 3. Security Review

### ✅ Passed Checks

- [チェック項目1]
- [チェック項目2]

### ❌ Critical Issues

#### CR-SEC-001: [Issue Title]
**Severity**: Critical
**File**: `[file_path]`
**Line**: [line_number]

**Issue**:
[問題の説明]

**Current Implementation**:
```ruby
[現在のコード（セキュリティリスクのあるコード）]
```

**Security Risk**:
[どのようなセキュリティリスクがあるか]

**Recommendation**:
[修正方法の提案]

**Related**: [development-guidelines.md Security section]

---

### ⚠️ Warnings

[同様のフォーマット]

---

### ℹ️ Info

[同様のフォーマット]

---

## 4. Testing Review

### ✅ Passed Checks

- [チェック項目1]
- [チェック項目2]

### ❌ Critical Issues

[issue-format.mdのフォーマットを使用]

---

### ⚠️ Warnings

#### WR-TEST-001: [Issue Title]
**Severity**: Warning
**File**: `[spec_file_path]`

**Issue**:
[問題の説明 - 欠落しているテストケース]

**Missing Tests**:
- [テストケース1]
- [テストケース2]

**Recommendation**:
[テスト追加の提案]

```ruby
# 推奨テストコード例
describe "..." do
  context "when ..." do
    it "..." do
      # ...
    end
  end
end
```

---

### ℹ️ Info

[同様のフォーマット]

---

## Summary & Next Actions

### Must Fix Before Merge (Critical: X)

1. **CR-SDD-001**: [Issue summary]
2. **CR-SEC-001**: [Issue summary]
3. **CR-XXX-XXX**: [Issue summary]

[修正が必要な理由を簡潔に説明]

---

### Should Address (Warning: X)

1. **WR-CODE-001**: [Issue summary]
2. **WR-TEST-001**: [Issue summary]
3. **WR-XXX-XXX**: [Issue summary]

[対処すべき理由を簡潔に説明]

---

### Recommended (Info: X)

1. **IF-CODE-001**: [Issue summary]
2. **IF-XXX-XXX**: [Issue summary]

[推奨する理由を簡潔に説明]

---

## Review Methodology

This review was conducted using the following checklists:

- [✅/❌] **SDD Consistency** (`.steering/[date]-[feature]/design.md`)
  - API-001〜004: API仕様整合性
  - DM-001〜003: データモデル整合性
  - BR-001〜002: ビジネスルール実装確認
  - TC-001〜002: テストケース網羅性

- ✅ **Coding Standards** (`docs/development-guidelines.md`)
  - LAYER-001〜005: レイヤーアーキテクチャ
  - NAME-001〜005: 命名規則
  - ANTI-001〜005: アンチパターン検出

- ✅ **Security** (`docs/development-guidelines.md` Security section)
  - SEC-001〜018: 認証・認可・パラメータ検証・機密情報管理

- ✅ **Testing** (`docs/development-guidelines.md` Test section)
  - TEST-001〜015: テストファイル存在・カバレッジ・品質

---

## Automated Tools Recommended

After addressing the issues above, please run the following automated tools:

```bash
# RuboCop（コードスタイルチェック）
bundle exec rubocop
bundle exec rubocop -a  # 自動修正

# Brakeman（セキュリティスキャン）
bundle exec brakeman

# RSpec + カバレッジ（テスト実行）
COVERAGE=true bundle exec rspec
# 目標: Line 90%以上、Branch 80%以上

# Bullet（開発環境でN+1クエリ検出）
# 開発サーバーを起動し、ログを確認してください
```

---

## Additional Notes

[その他の補足情報・コメント]

- [Note 1]
- [Note 2]

---

**Review Completed**: [ISO 8601タイムスタンプ]

---

*このレビューは、SDD（仕様駆動開発）ワークフローに基づき、仕様書との整合性を最優先で検証しています。Critical問題は必ず修正してください。*
