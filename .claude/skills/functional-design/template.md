# 機能設計書

## 概要

**機能名:** [機能の名称を記載]

**スコープ:** [この機能設計書がカバーする範囲を記述]

**例:**
この機能設計書は、ユーザー認証機能（新規登録、ログイン、ログアウト、パスワードリセット）とレッスン管理機能（作成、編集、削除、一覧表示）の詳細設計を定義します。

## 機能一覧

### ユーザー登録

#### 目的
新規ユーザー（講師または生徒）がアカウントを作成できるようにする

#### 対象ユーザー
未登録の訪問者

#### 入力
- メールアドレス（必須）
- パスワード（必須）
- パスワード確認（必須）
- 名前（必須）
- ユーザータイプ（講師/生徒、必須）

#### 処理フロー
1. ユーザーが登録フォームに情報を入力
2. クライアント側でバリデーション実施
   - メールアドレス形式チェック
   - パスワード強度チェック（8文字以上、英数字含む）
   - パスワード確認の一致チェック
3. `POST /api/v1/users` にリクエスト送信
4. サーバー側でバリデーション実施
5. メールアドレスの重複チェック
6. パスワードをbcryptでハッシュ化（cost=12）
7. ユーザーレコードをデータベースに保存（ステータス: `unconfirmed`）
8. 確認メール送信（非同期ジョブで実行）
9. JWTトークン発行（有効期限24時間）
10. レスポンス返却

#### 出力
**成功時:**
```json
{
  "status": "success",
  "data": {
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "山田太郎",
      "email": "yamada@example.com",
      "user_type": "teacher",
      "email_verified": false,
      "created_at": "2025-01-15T10:30:00Z"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**失敗時:**
```json
{
  "status": "error",
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": [
      {
        "field": "email",
        "message": "Email has already been taken"
      }
    ]
  }
}
```

#### エッジケース
- メールアドレスが既に登録されている場合 → 422エラー
- パスワードが脆弱な場合（辞書攻撃対策）→ 400エラー
- 大量の登録リクエスト → レート制限（1分間に5回まで）
- 確認メール送信失敗時 → 3回までリトライ、それでも失敗したらエラーログ記録

#### エラーハンドリング
- バリデーションエラー: 400 Bad Request
- メールアドレス重複: 422 Unprocessable Entity
- サーバーエラー: 500 Internal Server Error
- レート制限超過: 429 Too Many Requests

---

### レッスン作成

#### 目的
講師が新しいレッスンを作成し、生徒を割り当てられるようにする

#### 対象ユーザー
ログイン済みの講師

#### 入力
- タイトル（必須、1-100文字）
- 日時（必須、未来の日時のみ）
- 時間（必須、15-180分）
- 生徒ID（必須）
- 詳細（任意、最大1000文字）

#### 処理フロー
1. 講師がレッスン作成フォームに情報を入力
2. クライアント側でバリデーション実施
3. `POST /api/v1/lessons` にリクエスト送信（JWTトークン付き）
4. JWTトークンの検証（有効期限、ユーザータイプが講師か）
5. サーバー側でバリデーション実施
6. 生徒IDの存在確認
7. スケジュール重複チェック（同じ講師の同時刻のレッスンがないか）
8. レッスンレコードをデータベースに保存（ステータス: `scheduled`）
9. 生徒への通知メール送信（非同期ジョブで実行）
10. レスポンス返却

#### 出力
**成功時:**
```json
{
  "status": "success",
  "data": {
    "lesson": {
      "id": "lesson-uuid",
      "title": "数学の授業",
      "scheduled_at": "2025-02-01T14:00:00Z",
      "duration_minutes": 60,
      "status": "scheduled",
      "teacher": {
        "id": "teacher-uuid",
        "name": "山田先生"
      },
      "student": {
        "id": "student-uuid",
        "name": "佐藤花子"
      },
      "details": "二次方程式の解法を学習",
      "created_at": "2025-01-15T10:30:00Z"
    }
  }
}
```

#### エッジケース
- 過去の日時を指定した場合 → 400エラー
- 存在しない生徒IDを指定した場合 → 404エラー
- 同じ時刻に既にレッスンがある場合 → 422エラー
- 生徒が同時刻に別のレッスンを受講予定の場合 → 警告（作成は可能）

#### エラーハンドリング
- 認証エラー: 401 Unauthorized
- 権限エラー（講師以外）: 403 Forbidden
- バリデーションエラー: 400 Bad Request
- 生徒が見つからない: 404 Not Found
- スケジュール重複: 422 Unprocessable Entity

---

### 成績記録作成

#### 目的
講師がレッスン完了後に生徒の成績を記録できるようにする

#### 対象ユーザー
ログイン済みの講師（自分が担当したレッスンのみ）

#### 入力
- レッスンID（必須）
- スコア（必須、0-100の整数）
- フィードバック（任意、最大500文字）

#### 処理フロー
1. 講師が成績記録フォームに情報を入力
2. `POST /api/v1/lessons/:lesson_id/grade_records` にリクエスト送信
3. JWTトークンの検証
4. レッスンの存在確認と権限チェック（自分が担当した完了済みレッスンか）
5. サーバー側でバリデーション実施
6. 成績レコードをデータベースに保存
7. レッスンのステータスを `graded` に更新
8. 生徒への通知メール送信（非同期ジョブで実行）
9. レスポンス返却

#### 出力
**成功時:**
```json
{
  "status": "success",
  "data": {
    "grade_record": {
      "id": "grade-uuid",
      "lesson_id": "lesson-uuid",
      "score": 85,
      "feedback": "二次方程式の解法をよく理解しています。応用問題にも挑戦しましょう。",
      "created_at": "2025-02-01T16:00:00Z"
    }
  }
}
```

#### エッジケース
- レッスンがまだ完了していない場合 → 400エラー
- 既に成績が記録されている場合 → 422エラー（更新は別のエンドポイント）
- 他の講師のレッスンに成績を記録しようとした場合 → 403エラー

#### エラーハンドリング
- 認証エラー: 401 Unauthorized
- 権限エラー: 403 Forbidden
- レッスンが見つからない: 404 Not Found
- バリデーションエラー: 400 Bad Request
- 既に成績記録済み: 422 Unprocessable Entity

## 画面設計

### [画面名]

#### レイアウト
#### コンポーネント構成
#### 状態管理
#### バリデーションルール

## API設計

### POST /api/v1/users - ユーザー登録

**認証:** 不要

**リクエストヘッダー:**
```
Content-Type: application/json
```

**リクエストボディ:**
```json
{
  "user": {
    "name": "山田太郎",
    "email": "yamada@example.com",
    "password": "SecurePass123!",
    "password_confirmation": "SecurePass123!",
    "user_type": "teacher"
  }
}
```

**成功レスポンス: 201 Created**
```json
{
  "status": "success",
  "data": {
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "山田太郎",
      "email": "yamada@example.com",
      "user_type": "teacher",
      "email_verified": false,
      "created_at": "2025-01-15T10:30:00Z"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**エラーレスポンス: 422 Unprocessable Entity**
```json
{
  "status": "error",
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": [
      {
        "field": "email",
        "message": "Email has already been taken"
      },
      {
        "field": "password",
        "message": "Password is too weak"
      }
    ]
  }
}
```

---

### POST /api/v1/auth/login - ログイン

**認証:** 不要

**リクエストボディ:**
```json
{
  "email": "yamada@example.com",
  "password": "SecurePass123!"
}
```

**成功レスポンス: 200 OK**
```json
{
  "status": "success",
  "data": {
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "山田太郎",
      "email": "yamada@example.com",
      "user_type": "teacher"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**エラーレスポンス: 401 Unauthorized**
```json
{
  "status": "error",
  "error": {
    "code": "INVALID_CREDENTIALS",
    "message": "Invalid email or password"
  }
}
```

---

### POST /api/v1/lessons - レッスン作成

**認証:** 必須（JWTトークン）

**リクエストヘッダー:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json
```

**リクエストボディ:**
```json
{
  "lesson": {
    "title": "数学の授業",
    "scheduled_at": "2025-02-01T14:00:00Z",
    "duration_minutes": 60,
    "student_id": "student-uuid",
    "details": "二次方程式の解法を学習"
  }
}
```

**成功レスポンス: 201 Created**
```json
{
  "status": "success",
  "data": {
    "lesson": {
      "id": "lesson-uuid",
      "title": "数学の授業",
      "scheduled_at": "2025-02-01T14:00:00Z",
      "duration_minutes": 60,
      "status": "scheduled",
      "teacher": {
        "id": "teacher-uuid",
        "name": "山田先生"
      },
      "student": {
        "id": "student-uuid",
        "name": "佐藤花子"
      },
      "details": "二次方程式の解法を学習",
      "created_at": "2025-01-15T10:30:00Z"
    }
  }
}
```

**エラーレスポンス: 422 Unprocessable Entity**
```json
{
  "status": "error",
  "error": {
    "code": "SCHEDULE_CONFLICT",
    "message": "You already have a lesson scheduled at this time"
  }
}
```

---

### GET /api/v1/lessons - レッスン一覧取得

**認証:** 必須（JWTトークン）

**クエリパラメータ:**
- `status`: レッスンステータス（scheduled, completed, cancelled）
- `from_date`: 開始日（YYYY-MM-DD形式）
- `to_date`: 終了日（YYYY-MM-DD形式）
- `page`: ページ番号（デフォルト: 1）
- `per_page`: 1ページあたりの件数（デフォルト: 20、最大: 100）

**成功レスポンス: 200 OK**
```json
{
  "status": "success",
  "data": {
    "lessons": [
      {
        "id": "lesson-uuid-1",
        "title": "数学の授業",
        "scheduled_at": "2025-02-01T14:00:00Z",
        "duration_minutes": 60,
        "status": "scheduled",
        "student": {
          "id": "student-uuid",
          "name": "佐藤花子"
        }
      }
    ],
    "pagination": {
      "current_page": 1,
      "total_pages": 5,
      "total_count": 100,
      "per_page": 20
    }
  }
}
```

---

### POST /api/v1/lessons/:lesson_id/grade_records - 成績記録作成

**認証:** 必須（JWTトークン、講師のみ）

**リクエストボディ:**
```json
{
  "grade_record": {
    "score": 85,
    "feedback": "二次方程式の解法をよく理解しています。応用問題にも挑戦しましょう。"
  }
}
```

**成功レスポンス: 201 Created**
```json
{
  "status": "success",
  "data": {
    "grade_record": {
      "id": "grade-uuid",
      "lesson_id": "lesson-uuid",
      "score": 85,
      "feedback": "二次方程式の解法をよく理解しています。応用問題にも挑戦しましょう。",
      "created_at": "2025-02-01T16:00:00Z"
    }
  }
}
```

## データフロー

```
[ユーザー入力] → [バリデーション] → [ビジネスロジック] → [データベース] → [レスポンス]
```

## 状態遷移図

```
[初期状態] → [処理中] → [完了/エラー]
```

## バリデーション仕様

### ユーザー登録

| フィールド | 型 | 必須 | 制約 | エラーメッセージ |
|-----------|-----|------|------|------------------|
| name | string | ○ | 1-100文字 | Name is required and must be between 1 and 100 characters |
| email | string | ○ | メール形式、最大255文字、一意 | Invalid email format or email already exists |
| password | string | ○ | 8-72文字、英数字含む | Password must be at least 8 characters and include letters and numbers |
| password_confirmation | string | ○ | passwordと一致 | Password confirmation doesn't match |
| user_type | string | ○ | "teacher" または "student" | User type must be either teacher or student |

### レッスン作成

| フィールド | 型 | 必須 | 制約 | エラーメッセージ |
|-----------|-----|------|------|------------------|
| title | string | ○ | 1-100文字 | Title is required and must be between 1 and 100 characters |
| scheduled_at | datetime | ○ | 未来の日時 | Scheduled time must be in the future |
| duration_minutes | integer | ○ | 15-180 | Duration must be between 15 and 180 minutes |
| student_id | uuid | ○ | 存在するユーザーID | Student not found |
| details | string | × | 最大1000文字 | Details must be less than 1000 characters |

### 成績記録作成

| フィールド | 型 | 必須 | 制約 | エラーメッセージ |
|-----------|-----|------|------|------------------|
| score | integer | ○ | 0-100 | Score must be between 0 and 100 |
| feedback | string | × | 最大500文字 | Feedback must be less than 500 characters |

## セキュリティ考慮事項

### 認証・認可

**例:**
- **JWT認証:** すべての保護されたエンドポイントでJWTトークンを検証
- **トークン有効期限:** 24時間
- **ロールベースアクセス制御（RBAC）:**
  - 講師: レッスンの作成・編集・削除、成績記録の作成・編集
  - 生徒: 自分のレッスン・成績の閲覧のみ
- **所有権チェック:** ユーザーは自分のリソースのみアクセス可能

### 入力値検証

**例:**
- **サーバー側での必須検証:** クライアント側のバリデーションは回避可能なため、サーバー側で必ず検証
- **Strong Parameters（Rails）:** 許可されたパラメータのみ受け入れ
- **型チェック:** 期待される型と一致するか検証
- **範囲チェック:** 数値は許容範囲内か検証

### XSS対策

**例:**
- **出力エスケープ:** ユーザー入力を表示する際は必ずエスケープ
- **Content Security Policy (CSP):** CSPヘッダーを設定
- **サニタイゼーション:** HTMLタグを含む入力は適切にサニタイズ

### CSRF対策

**例:**
- **CSRFトークン:** 状態変更を伴うリクエスト（POST, PUT, DELETE）でトークン検証
- **SameSite Cookie:** Cookie属性を`SameSite=Strict`に設定

### SQLインジェクション対策

**例:**
- **パラメータ化クエリ:** ActiveRecordのプレースホルダーを使用
- **生SQLの禁止:** 可能な限りORMを使用、生SQLは避ける
- **入力値検証:** 特殊文字を適切にエスケープ

### レート制限

**例:**
- **登録・ログイン:** 1分間に5回まで（同一IPアドレス）
- **API全般:** 1時間に1000リクエストまで（認証済みユーザー）
- **パスワードリセット:** 1時間に3回まで

### データ保護

**例:**
- **パスワードハッシュ化:** bcrypt（cost=12）
- **個人情報の暗号化:** データベースレベルでの暗号化
- **HTTPS強制:** すべての通信をHTTPS経由で行う
- **センシティブデータのログ除外:** パスワード、トークンはログに記録しない
