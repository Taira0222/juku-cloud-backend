---
description: コードレビューを実施（SDD仕様書整合性・コーディング規約・セキュリティ・テスト品質）
---

# コードレビュー

> **Note**: このファイルは`.claude/agents/`配下に配置されたエージェント定義です。実際のレビューロジックは`.claude/skills/code-review/`にあります。

コード実装を4つの観点で包括的にレビューします：
1. **SDD仕様書（design.md）との一貫性**
2. **コーディング規約遵守**
3. **セキュリティベストプラクティス**
4. **テストカバレッジ・品質**

## クイックスタート

初めて使用する場合は、以下のコマンドを実行してください：

```bash
# 現在のブランチの変更をレビュー
/code-review
```

このコマンドは自動的に以下を実行します：
1. git diffで変更ファイルを検出
2. 対応する仕様書（`.steering/*/design.md`）を検索
3. 4つの観点でレビューを実施
4. マークダウンレポートを表示

**次のステップ**: レビュー結果のCritical問題を修正し、再度レビューを実行してください。

## 実行方法

```bash
# PR全体をレビュー（git diffを使用）
/code-review

# 特定ファイルをレビュー
/code-review app/controllers/api/v1/reports_controller.rb

# 複数ファイルをレビュー
/code-review app/controllers/api/v1/reports_controller.rb app/services/reports/generate_service.rb

# 特定機能をレビュー（.steering/配下）
/code-review .steering/20250131-student-report/

# ディレクトリ全体をレビュー
/code-review app/services/reports/
```

## 引数

- **引数なし**: PR全体（`git diff main...HEAD`の変更ファイル）
- **ファイルパス**: 指定されたファイルのみ
- **ディレクトリパス**: 配下の全Rubyファイル（*.rb）
- **`.steering/[date]-[feature]/`**: design.mdから実装ファイルリストを抽出してレビュー

### 引数の優先順位

複数の引数を指定した場合、最初の引数のみが有効です：

1. **`.steering/[date]-[feature]/` パス指定**: 最優先で`design.md`を読み込み、実装ファイルリストを抽出
2. **ファイルパス指定**: そのファイルのみレビュー（仕様書は自動検索）
3. **ディレクトリパス指定**: 配下の全*.rbファイルをレビュー（仕様書は自動検索）
4. **引数なし**: git diffで変更ファイルを自動検出（仕様書は自動検索）

## 手順

### ステップ1: 対象の特定

1. **引数なしの場合（PR全体レビュー）**:
   ```bash
   git diff --name-only main...HEAD
   ```
   で変更ファイルリストを取得し、Rubyファイル（*.rb）を抽出

2. **ファイルパス指定の場合**:
   - そのファイルを対象とする
   - 例: `/code-review app/controllers/api/v1/reports_controller.rb`

3. **ディレクトリ指定の場合**:
   - ディレクトリ配下の全Rubyファイル（*.rb）を対象とする
   - 例: `/code-review app/services/reports/`
   - 実行: `find app/services/reports/ -name "*.rb"`

4. **`.steering/`指定の場合**:
   - `.steering/[date]-[feature]/design.md`を読み込み
   - 「実装の参照」セクションからファイルパスリストを抽出
   - それらのファイルを対象とする
   - 例: `/code-review .steering/20250131-student-report/`

### ステップ2: 仕様書の検索

対象ファイルに対応する`.steering/*/design.md`を検索：

1. **PR説明から検索**:
   - PR説明に`.steering/`へのリンクがあれば使用

2. **ファイル名から推測**:
   - ファイル名から機能名を抽出（以下のパターンマッチング）
     - `app/controllers/api/v1/reports_controller.rb` → `reports`
     - `app/services/students/create_service.rb` → `students`
     - `app/models/lesson_note.rb` → `lesson_note` または `lesson-note`
   - 検索: `ls .steering/*-{機能名}*/design.md`
   - 例: `reports_controller.rb` → `ls .steering/*-report*/design.md`

3. **複数マッチ時**:
   - 最新（ディレクトリ名が`YYYYMMDD-*`形式であることを前提とし、日付部分を数値比較）を使用

4. **マッチなし時**:
   - SDD仕様書整合性チェックをスキップ
   - コーディング規約・セキュリティ・テストのみレビュー

### ステップ3: code-reviewスキル起動

`code-review`スキルを呼び出し、以下を渡す：

- **対象ファイルリスト**: レビュー対象の全Rubyファイル
- **仕様書パス**: `.steering/*/design.md`（存在する場合）
- **レビュー観点**: 4つすべて（SDD整合性・コーディング規約・セキュリティ・テスト品質）

### ステップ4: レビュー結果の表示

スキルが生成したマークダウンレポートを表示します。

レポート構成：
- **Executive Summary**: 重大度別の問題数集計
- **SDD Specification Consistency Review**: 仕様書との整合性チェック結果
- **Coding Standards Review**: コーディング規約チェック結果
- **Security Review**: セキュリティレビュー結果
- **Testing Review**: テスト品質チェック結果
- **Summary & Next Actions**: 次のアクションリスト

## 出力形式

詳細なマークダウンレポート（テンプレート: `.claude/skills/code-review/templates/review-report.md`）

### レビューレポートのサンプル

以下は、実際のレビューレポートの例です：

```markdown
# コードレビューレポート

**レビュー対象**: PR #123 - 生徒レポート機能
**レビュー日時**: 2025-01-31T10:00:00Z
**レビューファイル数**: 8ファイル

## 概要

| カテゴリ | Critical | Warning | Info | 合計 |
|----------|----------|---------|------|------|
| SDD仕様書整合性 | 1 | 2 | 0 | 3 |
| コーディング規約 | 0 | 3 | 2 | 5 |
| セキュリティ | 1 | 0 | 0 | 1 |
| テスト品質 | 0 | 2 | 1 | 3 |
| **合計** | **2** | **7** | **3** | **12** |

**総合評価**: ⚠️ 修正が必要

マージ前に2件のCritical問題の修正が必須です。

## Critical問題

### [CRITICAL] SEC-001: 認証チェック不足
**ファイル**: `app/controllers/api/v1/reports_controller.rb:15`
**説明**: `create`アクションに`authenticate_user!`のbefore_actionが設定されていません。
**影響**: 未認証ユーザーがレポートを生成できてしまいます。
**修正方法**: `before_action :authenticate_user!, only: [:create]`を追加してください。

### [CRITICAL] API-002: design.mdとのレスポンス形式不一致
**ファイル**: `app/controllers/api/v1/reports_controller.rb:23`
**説明**: レスポンスが仕様書で定義された`report_url`ではなく`report_path`を返しています。
**影響**: API仕様違反により、フロントエンドとの連携に問題が発生します。
**修正方法**: `report_path`を`report_url`に変更し、仕様書と一致させてください。

...
```

### 重大度分類

- **Critical**: マージ前に必ず修正（マージブロッカー、レビュアー承認を得る前に修正が必須）
  - SDD仕様書違反（API不一致、BR未実装）
  - セキュリティ問題（認証欠如、SQLインジェクションリスク）
  - 必須テスト欠如（design.mdのTC-XXX未実装）

- **Warning**: 対処すべき
  - コードスタイル違反（RuboCop以上）
  - N+1クエリ
  - エッジケーステスト欠如
  - マジックナンバー

- **Info**: 推奨
  - ドキュメント改善提案
  - パフォーマンス最適化
  - リファクタリング機会

**詳細な判断基準**: [guide.md - 重大度の判断基準](.claude/skills/code-review/guide.md#重大度severityの判断基準)を参照してください。

## レビュー観点

### 1. SDD仕様書整合性

**チェックリスト**: `skills/code-review/checklists/sdd-consistency.md`

- API-001〜004: APIエンドポイント・パラメータ・レスポンス・ステータスコード
- DM-001〜003: データモデル（カラム・リレーション・インデックス）
- BR-001〜002: ビジネスルール実装確認
- TC-001〜002: テストケース網羅性
- SEC-001: セキュリティ要件実装確認
- PERF-001: パフォーマンス要件実装確認

### 2. コーディング規約

**チェックリスト**: `skills/code-review/checklists/coding-standards.md`

- LAYER-001〜005: レイヤーアーキテクチャ（Controller, Service, Query, Model, Serializer）
- NAME-001〜005: 命名規則（snake_case, PascalCase, UPPER_SNAKE_CASE, ?, !）
- ANTI-001〜005: アンチパターン検出（Fat Controller, Fat Model, マジックナンバー等）
- STYLE-001〜004: コードスタイル（インデント、行長、文字列リテラル等）
- COMMENT-001〜002: コメント品質

### 3. セキュリティ

**チェックリスト**: `skills/code-review/checklists/security.md`

- SEC-001〜003: 認証・認可（authenticate_user!, require_admin_role!）
- SEC-004〜005: パスワード・トークンセキュリティ
- SEC-006〜008: 機密情報管理（ENV変数、ハードコーディング禁止）
- SEC-009〜011: インジェクション攻撃防止（SQL, XSS, CSRF）
- SEC-012〜014: トークン生成・ハッシュ化・レート制限
- SEC-015〜016: データアクセス制御・ログフィルタリング
- SEC-017〜018: Brakeman・Bundler Audit

### 4. テスト品質

**チェックリスト**: `skills/code-review/checklists/testing.md`

- TEST-001〜002: テストファイル存在・カバレッジ目標達成
- TEST-003〜005: RSpec形式・AAAパターン・FactoryBot使用
- TEST-006: Modelテスト（validations, associations, scopes）
- TEST-007〜008: Serviceテスト（正常系・異常系・エッジケース・トランザクション）
- TEST-009: リクエストテスト（成功・エラー・認証・認可・レスポンス形式）
- TEST-010〜011: Queryテスト（N+1回避・フィルター・ソート）
- TEST-012〜015: エッジケース・テスト独立性・命名・データ品質

## 推奨ワークフロー

以下の順序でレビューを実施することを推奨します：

### ステップ1: 実装前
- [ ] `.steering/[date]-[feature]/design.md`を作成
- [ ] 仕様レビューを取得（仕様レビューPR）

### ステップ2: 実装後、PR作成前
- [ ] RuboCop実行: `bundle exec rubocop -a`（自動修正）
- [ ] テスト実行: `COVERAGE=true bundle exec rspec`
- [ ] Bullet確認: 開発サーバーログでN+1クエリをチェック

### ステップ3: PR作成後
- [ ] `/code-review`実行（このスキル）
- [ ] Critical問題を修正
- [ ] Brakeman実行: `bundle exec brakeman`
- [ ] 再度`/code-review`実行（Critical問題が0になるまで繰り返し）

### ステップ4: レビュアー承認
- [ ] レビュアーに承認依頼
- [ ] フィードバック対応

### ステップ5: マージ
- [ ] mainブランチへマージ
- [ ] CI/CD自動デプロイ確認

## 注意事項

### レビュー時間の目安

| ファイル数 | 推定時間 |
|----------|---------|
| 1-5ファイル | 30秒-1分 |
| 6-20ファイル | 1-3分 |
| 21-50ファイル | 3-7分 |
| 51ファイル以上 | 7分以上（分割推奨） |

**注意**: ファイルサイズ・複雑度により時間は前後します。

### Critical問題への対処

- Critical問題が見つかった場合、マージ前に必ず修正してください（マージブロッカー）
- セキュリティ問題は最優先で対処してください

### 自動ツールとの併用

このスキルは自動ツール（RuboCop, Brakeman等）の補完として使用します。
上記の推奨ワークフローに従って、各ツールを適切なタイミングで実行してください：

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

## 使用例

### 例1: PR全体レビュー

```bash
/code-review
```

**動作**:
1. `git diff main...HEAD`で変更ファイル取得
2. Rubyファイル（*.rb）を抽出
3. 対応する`.steering/*/design.md`を検索
4. 4つの観点でレビュー実施
5. マークダウンレポート生成・表示

### 例2: 特定機能レビュー

```bash
/code-review .steering/20250131-student-report/
```

**動作**:
1. `.steering/20250131-student-report/design.md`読み込み
2. 「実装の参照」セクションからファイルリスト抽出
   - `app/controllers/api/v1/reports_controller.rb`
   - `app/services/reports/generate_service.rb`
   - `app/models/report.rb`
   - `spec/requests/api/v1/reports_spec.rb`
3. これらのファイルを対象にレビュー実施
4. design.mdとの整合性を重点チェック

### 例3: 特定ファイルレビュー

```bash
/code-review app/controllers/api/v1/reports_controller.rb
```

**動作**:
1. 指定ファイルのみレビュー
2. ファイル名から機能名（reports）を推測
3. `.steering/*-report*/design.md`を検索
4. 見つかれば仕様書整合性もチェック

### 例4: ディレクトリレビュー

```bash
/code-review app/services/reports/
```

**動作**:
1. `app/services/reports/`配下の全*.rbファイル取得
2. 各ファイルをレビュー
3. 対応する仕様書を検索してチェック

## トラブルシューティング

### 仕様書が見つからない

**問題**: "No design.md specification found"と表示される

**解決策**:
1. `.steering/`ディレクトリに該当機能のdesign.mdが存在するか確認
2. ファイル名が正しいか確認（`design.md`）
3. 手動で仕様書パスを指定：
   ```bash
   /code-review .steering/20250131-student-report/
   ```
4. このプロジェクトでSDD方法論を使用していない場合、仕様書チェックはスキップされます（正常動作）

### `.steering/`ディレクトリが存在しない

**問題**: ".steering/ directory not found"と表示される

**解決策**:
1. このプロジェクトでSDD方法論を使用しているか確認
2. 使用している場合、`.steering/`ディレクトリを作成し、`design.md`を追加
3. 使用していない場合、仕様書チェックはスキップされます（正常動作）

### git diffが失敗する

**問題**: "git diff failed"と表示される

**解決策**:
1. Gitリポジトリ内で実行しているか確認
2. mainブランチが存在するか確認（`git branch -a`）
3. リモート追跡ブランチが設定されているか確認（`git remote -v`）

### レビュー時間が長い

**問題**: レビューに7分以上かかる

**解決策**:
1. 対象ファイルを10-20ファイル以下に分割
2. ディレクトリ単位で分割してレビュー（例: Controllerのみ、Serviceのみ）
3. 複数回に分けてレビューを実行

### Critical問題が多すぎる

**問題**: Critical問題が10件以上検出される

**解決策**:
1. まずCritical問題のみに集中して修正
2. 修正後、再度レビュー実行
3. Warning・Infoは後から対処

## 関連ドキュメント

- [SKILL.md](../skills/code-review/SKILL.md) - スキル詳細仕様
- [guide.md](../skills/code-review/guide.md) - 詳細ガイドライン
- [checklists/](../skills/code-review/checklists/) - 各チェックリスト
- [templates/](../skills/code-review/templates/) - レポートテンプレート
- [CLAUDE.md](/CLAUDE.md) - プロジェクト全体ガイド
- [docs/development-guidelines.md](/docs/development-guidelines.md) - 開発ガイドライン

---

**このコマンドは、SDD（仕様駆動開発）ワークフローにおける実装レビューの品質を保証します。**
