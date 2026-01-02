# 既存プロジェクト（Juku Cloud Backend）へのSDD導入計画

## エグゼクティブサマリー

Juku Cloud Backendに、`.steering/` ベースのワークフローとSDD（仕様駆動開発）を統合した開発体制を構築します。

**コアコンセプト**:
- 📁 **`.steering/[YYYYMMDD]-[feature]/`** - 機能開発ごとの作業ディレクトリ（履歴として永続化)
- 📚 **`docs/`** - プロダクト全体の永続的ドキュメント（全体設計）
- 🤖 **`.claude/`** - agents/skills/commands でClaude Code機能をフル活用

---

## プロジェクト概要
- **プロジェクト**: Juku Cloud Backend（塾管理システムのRails API）
- **技術スタック**: Ruby on Rails 8.0 (API mode), PostgreSQL, AWS (ECS, RDS)
- **現状**: 高いテストカバレッジ（98%）、明確なコーディング規約、GitHub Flow採用

## 目標設定

### ユーザーの要望
1. **ドキュメント体系**: `docs/` と `.steering/` の二層構造
2. **開発ワークフロー**: `.steering/[date]-[feature]/` で機能ごとに開発
3. **仕様書**: `.steering/*/design.md` が仕様書の役割
4. **Claude Code活用**: `.claude/` 配下でagents/skills/commandsをフル活用

### SDD導入の期待効果
- 機能開発履歴の可視化（`.steering/` に全履歴が残る）
- 仕様レビュー文化の定着（`design.md` レビュー必須）
- 全体設計と個別設計の分離（`docs/` vs `.steering/`）
- AI駆動開発の加速（`.claude/` 活用）

---

## 提案するディレクトリ構造

```
/app/juku-cloud-backend/
├── docs/                                      # 永続的ドキュメント（プロダクト全体）
│   ├── product-requirements.md                # PRD（プロダクト要求定義書）
│   ├── functional-design.md                   # 機能設計書（全体アーキテクチャ・共通設計）
│   ├── architecture.md                        # 技術仕様書（インフラ・技術スタック）
│   ├── repository-structure.md                # リポジトリ構造定義書
│   ├── development-guidelines.md              # 開発ガイドライン
│   └── glossary.md                            # ユビキタス言語定義（ドメイン用語集）
│
├── .steering/                                 # 機能開発ごとの作業ディレクトリ（履歴として保存）
│   ├── 20250115-teacher-invitation/           # 例：教師招待機能
│   │   ├── requirements.md                    # 要件定義（背景・目的・ユーザーストーリー）
│   │   ├── design.md                          # 仕様書（SDD の中核）★
│   │   └── tasklist.md                        # タスクリスト（実装タスク・進捗管理）
│   ├── 20250120-lesson-notes-crud/
│   │   ├── requirements.md
│   │   ├── design.md
│   │   └── tasklist.md
│   └── README.md                              # .steering/ の使い方ガイド
│
├── .claude/                                   # Claude Code 拡張機能
│   ├── agents/                                # カスタムサブエージェント
│   │   └── (今後追加予定)
│   ├── commands/                              # スラッシュコマンド
│   │   └── (今後追加予定)
│   └── skills/                                # スキル
│       └── (今後追加予定)
│
├── CLAUDE.md                                  # ★ Claude用プロジェクトガイド（最重要）
├── .github/
│   ├── CONTRIBUTING.md                        # 既存（SDD章を追加）
│   └── PULL_REQUEST_TEMPLATE.md               # 既存（.steering/リンク項目追加）
│
└── (app/, spec/, config/ など既存ファイル)
```

---

## ドキュメント体系の詳細

### 1. `docs/` - 永続的ドキュメント（プロダクト全体）

| ファイル | 役割 | 更新タイミング |
|---------|------|---------------|
| **product-requirements.md** | プロダクト要求定義書（PRD）<br>- プロダクトビジョンと目的<br>- ターゲットユーザーと課題・ニーズ<br>- 主要な機能一覧<br>- 成功の定義<br>- ビジネス要件<br>- ユーザーストーリー<br>- 受け入れ条件<br>- 機能要件<br>- 非機能要件 | プロダクト方針変更時 |
| **functional-design.md** | 機能設計書<br>- 機能ごとのアーキテクチャ<br>- システム構成図<br>- データモデル定義（ER図含む）<br>- コンポーネント設計<br>- ユースケース図、画面遷移図、ワイヤフレーム<br>- API設計（将来的にバックエンドと連携する場合） | 新機能追加でアーキテクチャに影響がある場合 |
| **architecture.md** | 技術仕様書<br>- テクノロジースタック<br>- 開発ツールと手法<br>- 技術的制約と要件<br>- パフォーマンス要件 | インフラ変更時 |
| **repository-structure.md** | リポジトリ構造定義書<br>- フォルダ・ファイル構成<br>- ディレクトリの役割<br>- ファイル配置ルール | ディレクトリ構造変更時 |
| **development-guidelines.md** | 開発ガイドライン<br>- コーディング規約<br>- 命名規則<br>- スタイリング規約<br>- テスト規約<br>- Git規約 | 開発プロセス変更時 |
| **glossary.md** | ユビキタス言語定義<br>- ドメイン用語の定義<br>- ビジネス用語の定義<br>- UI/UX用語の定義<br>- 英語・日本語対応表<br>- コード上の命名規則 | 新しいドメイン概念追加時 |

### 2. `.steering/[YYYYMMDD]-[feature]/` - 機能開発ごとの作業ディレクトリ

各機能開発で以下の3ファイルを作成：

#### `requirements.md` - 要件定義
```markdown
# [機能名] 要件定義

## 背景・目的
なぜこの機能が必要か

## ユーザーストーリー
- As a [ユーザー], I want to [アクション], so that [目的]

## ビジネス要件
- 解決すべき課題
- 成功指標（KPI）

## 制約条件
- 技術的制約
- スケジュール制約
```

#### `design.md` - 仕様書（SDD の中核）★
```markdown
# [機能名] 仕様書

## 概要
機能の簡潔な説明

## ユースケース
### UC-001: [ユースケース名]
- アクター:
- 前提条件:
- 基本フロー:
- 代替フロー:
- 事後条件:

## データモデル
- テーブル定義
- リレーションシップ
- インデックス

## API仕様
### POST /api/v1/xxx
- リクエスト
- レスポンス
- エラーケース

## ビジネスルール
- BR-001: [ルール名] - 詳細

## セキュリティ要件
- 認証・認可
- データ保護

## テスト戦略
- テストケース一覧
- カバレッジ目標

## 実装の参照
- 関連ファイルパス
- 既存パターンの参照

## 変更履歴
- 2025-XX-XX: 初版作成
```

#### `tasklist.md` - タスクリスト
```markdown
# [機能名] タスクリスト

## 設計フェーズ
- [ ] requirements.md 作成
- [ ] design.md 作成・レビュー承認

## 実装フェーズ
- [ ] モデル作成
- [ ] サービス作成
- [ ] コントローラー作成
- [ ] テスト作成

## レビュー・マージ
- [ ] PR作成
- [ ] レビュー対応
- [ ] マージ

## 完了後
- [ ] docs/ への反映（必要に応じて）
```

### 3. `CLAUDE.md` - Claude用プロジェクトガイド

Claudeが参照する最重要ドキュメント：

```markdown
# CLAUDE.md - Claude Code プロジェクトガイド

## このプロジェクトについて

Juku Cloud BackendはRails APIプロジェクトで、SDD（仕様駆動開発）を`.steering/`ワークフローで実践しています。

## ドキュメント体系

### `docs/` - プロダクト全体の永続的ドキュメント
- `functional-design.md`: システム全体の機能設計（全体アーキテクチャ）
- その他PRD、技術仕様、開発ガイドラインなど

### `.steering/[YYYYMMDD]-[feature]/` - 機能開発の作業ディレクトリ
- `requirements.md`: 要件定義
- **`design.md`: 仕様書（SDDの中核）**
- `tasklist.md`: タスクリスト

**重要**: 開発完了後も `.steering/` は削除せず、履歴として永続化します。

## SDD（仕様駆動開発）ワークフロー

### 新機能開発の流れ

1. **作業ディレクトリ作成**
   ```bash
   mkdir -p .steering/$(date +%Y%m%d)-[feature-name]
   cd .steering/$(date +%Y%m%d)-[feature-name]
   ```

2. **要件定義作成**
   - `requirements.md` を作成
   - 背景・ユーザーストーリー・ビジネス要件を明記

3. **設計書（仕様書）作成** ★ SDDの中核
   - `design.md` を作成
   - ユースケース、API仕様、データモデル、テスト戦略を詳細に記述
   - **この時点でレビューを取得（PR作成）**

4. **設計レビュー（仕様レビュー）**
   - `design.md` のみのPRを作成（ラベル: `spec-review`）
   - 技術メンバー2名以上の承認必須
   - レビュー観点:
     - 技術的実現可能性
     - API設計の一貫性
     - エッジケース網羅性
     - セキュリティ・パフォーマンス要件
   - 目標: 24時間以内の承認

5. **実装フェーズ**
   - `tasklist.md` を作成
   - `design.md` に基づいてTDDで実装
   - 仕様書と実装を常に同期

6. **実装レビュー**
   - 実装コードのPRを作成
   - PR説明に `.steering/[date]-[feature]/design.md` へのリンクを記載
   - レビュー観点:
     - **仕様書（design.md）との一貫性（最重要）**
     - コード品質（RuboCop）
     - テストカバレッジ（Line 90%以上）

7. **完了後の処理**
   - `.steering/` は削除せず残す（履歴）
   - 必要に応じて `docs/functional-design.md` を更新
     - 例：新しいアーキテクチャパターンを追加した場合

### Claude Code を使う際のベストプラクティス

#### 新機能開発を依頼する場合

「〇〇機能を開発したい」と伝えると、Claudeは以下を自動で行います：

1. `.steering/[date]-[feature]/` ディレクトリ作成
2. `requirements.md` 作成（背景・ユーザーストーリー確認）
3. `design.md` 作成（仕様書として詳細設計）
4. `tasklist.md` 作成
5. 仕様レビューPR作成
6. 承認後、実装開始

#### 既存機能の仕様書化

「〇〇機能の仕様書を作成して」と伝えると：

1. 既存コード・テストを分析
2. `.steering/[date]-[feature-retro-spec]/` 作成
3. `design.md` に仕様を逆算して記述

## `.claude/` ディレクトリの活用

### `agents/` - カスタムサブエージェント
（今後実装予定）

### `commands/` - スラッシュコマンド
（今後実装予定）

### `skills/` - スキル
（今後実装予定）

## 参照すべきファイル

Claudeが開発を行う際は以下を参照してください：

1. **`CLAUDE.md`** （このファイル）- まず最初に読む
2. **`docs/functional-design.md`** - システム全体の設計方針
3. **`docs/development-guidelines.md`** - コーディング規約・テスト戦略
4. **`docs/glossary.md`** - ドメイン用語の正確な定義
5. **`.steering/[最新のfeature]/design.md`** - 関連機能の実装パターン参照

## よくある質問

### Q: `docs/functional-design.md` と `.steering/*/design.md` の違いは？
A:
- `docs/functional-design.md` = システム**全体**の機能設計・アーキテクチャ
- `.steering/*/design.md` = **個別機能**の詳細設計（仕様書）

### Q: 開発完了後、`.steering/` は削除する？
A: いいえ、削除しません。履歴として永続化し、過去の意思決定を追跡できるようにします。

### Q: `design.md` に書くべきレベルは？
A:
- ユースケース（フローチャート相当）
- API仕様（リクエスト/レスポンス例）
- データモデル（テーブル定義）
- ビジネスルール（バリデーション・計算ロジック）
- テストケース（正常系・異常系・境界値）

**実装者が迷わず開発できる**レベルの詳細度を目指してください。

---

以上がこのプロジェクトのドキュメント体系とワークフローです。
新しい開発タスクを始める際は、必ずこのガイドに従ってください。
```

---

## 付録A: `design.md` サンプル（Teacher Invitation機能）

`.steering/20250115-teacher-invitation-retro-spec/design.md`:

```markdown
# Teacher Invitation（教師招待）機能 - 設計書 / 仕様書

## 概要

School（塾）の管理者が新しい教師を招待するためのトークンベース招待システム。
セキュアなトークンを生成し、教師がそのトークンを使用してアカウント登録を完了できる。

## ユースケース

### UC-001: 招待トークン生成（管理者）

- **アクター**: School管理者（admin role）
- **前提条件**:
  - ユーザーがログイン済み
  - ユーザーが `admin` role を持つ
  - ユーザーが所属するSchoolが存在する
- **トリガー**: 管理者が「新しい教師を招待」ボタンをクリック
- **基本フロー**:
  1. 管理者が `POST /api/v1/invites` をリクエスト
  2. システムがユーザーの認証情報を確認
  3. システムがユーザーのroleが `admin` であることを確認
  4. システムが32バイトのURLセーフなランダムトークンを生成
  5. システムがトークンをHMAC-SHA256でハッシュ化してDBに保存
  6. システムが生のトークン（raw_token）をレスポンスとして返す
  7. フロントエンドが招待用URLを生成
- **代替フロー**:
  - 3a. ユーザーが未認証 → 401 Unauthorized
  - 3b. ユーザーが `teacher` role → 403 Forbidden
- **事後条件**:
  - 新しいInviteレコードがDBに作成される
  - トークンの有効期限は7日後に設定される

### UC-002: 招待トークン検証（招待される教師）

- **アクター**: 招待される教師（未登録ユーザー）
- **前提条件**: 管理者から招待トークンを受け取っている
- **トリガー**: 招待URLにアクセス
- **基本フロー**:
  1. 教師が招待URL（トークン含む）をブラウザで開く
  2. フロントエンドが `GET /api/v1/invites/{token}` をリクエスト
  3. システムがトークンをHMAC-SHA256でハッシュ化
  4. システムがハッシュ値でInviteレコードを検索
  5. システムが招待の有効性をチェック（期限切れ、使用回数上限）
  6. システムがSchool名をレスポンスで返す
  7. フロントエンドが登録フォームを表示
- **代替フロー**:
  - 4a. トークンが存在しない → 404 Not Found
  - 5a. 期限切れ → 404 Not Found
  - 5b. 使用回数上限 → 404 Not Found

### UC-003: 招待トークン消費（登録完了時）

- **アクター**: システム（User登録サービス内で自動実行）
- **前提条件**: 招待トークンが有効、教師が登録フォームを送信
- **トリガー**: User登録完了時
- **基本フロー**:
  1. User登録処理が完了
  2. システムが `invite.consume!` を実行
  3. `uses_count` が +1 される
  4. `max_uses == 1` の場合、`used_at` に現在時刻が記録される

## データモデル

### Inviteモデル

| 属性 | 型 | 必須 | デフォルト | 説明 |
|------|-----|------|------------|------|
| `id` | bigint | ○ | - | プライマリキー |
| `token_digest` | string | ○ | - | HMAC-SHA256ハッシュ化されたトークン（UNIQUE） |
| `school_id` | bigint | ○ | - | 招待元のSchool（FK） |
| `role` | enum | ○ | `teacher` | 招待されるユーザーのrole |
| `expires_at` | datetime | ○ | 7日後 | トークンの有効期限 |
| `max_uses` | integer | ○ | 1 | 最大使用回数 |
| `uses_count` | integer | ○ | 0 | 現在の使用回数 |
| `used_at` | datetime | - | null | 最終使用日時 |
| `created_at` | datetime | ○ | - | 作成日時 |
| `updated_at` | datetime | ○ | - | 更新日時 |

### リレーションシップ
- `Invite` belongs_to `School` (1:N)
- `Invite` has_one `User` (1:1)

### インデックス
- `token_digest` (UNIQUE)
- `school_id`

## ビジネスルール

### BR-001: トークン生成アルゴリズム
- **ルール**: 暗号学的に安全な乱数生成器を使用
- **実装**: `SecureRandom.urlsafe_base64(32)`

### BR-002: トークンのハッシュ化
- **ルール**: 生のトークンはDBに保存せず、HMAC-SHA256ハッシュ値のみ保存
- **実装**: `OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, raw_token)`
- **理由**: DB漏洩時のセキュリティリスク軽減

### BR-003: トークンの有効期限
- **ルール**: デフォルトで7日間有効

### BR-004: 使用回数制限
- **ルール**: デフォルトで1回のみ使用可能

### BR-005: 招待の有効性判定
- **ルール**: 期限切れでない AND 使用回数上限に達していない

## API仕様

### 1. POST /api/v1/invites - 招待トークン生成

#### 認証・認可
- **認証**: 必須（Token認証）
- **権限**: Admin role必須

#### リクエスト
```http
POST /api/v1/invites HTTP/1.1
Host: api.juku-cloud.com
access-token: xxx
client: xxx
uid: admin@example.com
```

#### レスポンス

**成功時 (201 Created)**:
```json
{
  "token": "Xy9zAbC123..."
}
```

**エラー**:
- 401 Unauthorized: 未認証
- 403 Forbidden: Teacher role

### 2. GET /api/v1/invites/:token - 招待トークン検証

#### 認証・認可
- **認証**: 不要

#### リクエスト
```http
GET /api/v1/invites/Xy9zAbC123... HTTP/1.1
```

#### レスポンス

**成功時 (200 OK)**:
```json
{
  "school_name": "〇〇塾 本校"
}
```

**エラー**:
- 404 Not Found: トークン無効・期限切れ・使用済み

## セキュリティ要件

### SEC-001: トークンの秘匿性
- 生トークンはレスポンスでのみ返却
- DBにはHMAC-SHA256ハッシュのみ保存

### SEC-002: 権限チェック
- トークン生成はAdmin roleのみ
- `require_admin_role!` concernで実装

### SEC-003: トークンの予測不可能性
- `SecureRandom.urlsafe_base64(32)` 使用（エントロピー256ビット）

## パフォーマンス要件

### PERF-001: レスポンス時間
- **目標**: 95パーセンタイルで200ms以内
- **測定**: CloudWatch Logs Insights

### PERF-002: データベースクエリ
- トークン検索は `token_digest` UNIQUEインデックス使用
- N+1クエリなし

## テスト戦略

### カバレッジ目標
- Line: > 95%
- Branch: > 90%

### テストケース

#### TC-001: 招待トークン生成（正常系）
- **入力**: 認証済みAdminユーザー、`POST /api/v1/invites`
- **期待結果**: 201 Created、`token` キー含むJSON
- **実装**: `spec/requests/api/v1/invites_spec.rb:26`

#### TC-002: 招待トークン生成（権限エラー）
- **入力**: Teacher roleユーザー
- **期待結果**: 403 Forbidden
- **実装**: `spec/requests/api/v1/invites_spec.rb:32`

#### TC-003: 招待トークン検証（正常系）
- **入力**: 有効なトークン
- **期待結果**: 200 OK、`school_name` 含む
- **実装**: `spec/requests/api/v1/invites_spec.rb:7`

#### TC-004: 招待トークン検証（無効）
- **入力**: 存在しないトークン
- **期待結果**: 404 Not Found
- **実装**: `spec/requests/api/v1/invites_spec.rb:13`

#### TC-005: 期限切れトークン
- **入力**: `expires_at` が過去
- **期待結果**: 404 Not Found
- **実装**: `spec/services/invites/validator_spec.rb`

#### TC-006: 使用回数上限トークン
- **入力**: `uses_count >= max_uses`
- **期待結果**: 404 Not Found
- **実装**: `spec/services/invites/validator_spec.rb`

#### TC-007: トークン消費
- **操作**: `invite.consume!`
- **期待結果**: `uses_count` +1、`used_at` 更新
- **実装**: `spec/models/invite_spec.rb`

## 実装の参照

### 重要なファイル

| カテゴリ | ファイルパス |
|---------|-------------|
| **コントローラー** | `app/controllers/api/v1/invites_controller.rb` |
| **モデル** | `app/models/invite.rb` |
| **サービス** | `app/services/invites/token_generate.rb` |
| **サービス** | `app/services/invites/validator.rb` |
| **テスト** | `spec/requests/api/v1/invites_spec.rb` |
| **テスト** | `spec/services/invites/token_generate_spec.rb` |
| **テスト** | `spec/services/invites/validator_spec.rb` |

### データベーススキーマ

```ruby
create_table "invites", force: :cascade do |t|
  t.string "token_digest", null: false
  t.bigint "school_id", null: false
  t.integer "role", default: 0, null: false
  t.datetime "expires_at", null: false
  t.integer "max_uses", default: 1, null: false
  t.integer "uses_count", default: 0, null: false
  t.datetime "used_at"
  t.timestamps

  t.index ["token_digest"], unique: true
  t.index ["school_id"]
end
```

## 変更履歴
- 2025-01-15: 初版作成（既存実装の仕様書化）
```

