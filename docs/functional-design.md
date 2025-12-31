# 機能設計書

## 概要

**スコープ:** この機能設計書は、Juku Cloud Backendの全機能（ユーザー認証・招待、生徒管理、授業記録管理、科目管理）の詳細設計を定義します。

## 機能一覧

### 1. 講師招待（Invite Token Generation）

#### 目的
School管理者が新しい講師を安全に招待するため、暗号学的に安全なトークンを生成する

#### 対象ユーザー
ログイン済みのSchool管理者（admin role）

#### 入力
- なし（認証情報からSchoolを特定）

#### 処理フロー
1. 管理者が招待トークン生成をリクエスト
2. `POST /api/v1/invites` にリクエスト送信（access-token/client/uidヘッダー付き）
3. devise_token_authによるトークン検証
4. ユーザーのroleが `admin` であることを確認（`require_admin_role!`）
5. ユーザーの所属Schoolを取得（`set_school!`）
6. `Invites::TokenGenerate` サービスを呼び出し
   - `SecureRandom.urlsafe_base64(32)` で生トークン生成（256ビットエントロピー）
   - 生トークンをHMAC-SHA256でハッシュ化（`Rails.application.secret_key_base`使用）
   - Inviteレコード作成（`token_digest`、`school_id`、`expires_at: 7日後`、`max_uses: 1`）
7. 生トークン（raw token）を返却
8. クライアントが招待URL（`https://frontend.example.com/register?token=xxx`）を生成

#### 出力

**成功時（201 Created）:**
```json
{
  "token": "Xy9zAbC123..."
}
```

**エラー:**
- 401 Unauthorized: 未認証
- 403 Forbidden: teacher roleのユーザー

#### エッジケース
- 既に期限切れの招待トークンが存在する場合 → 削除せず履歴として保持
- 同一管理者が連続してトークンを生成する場合 → 無制限に生成可能（レート制限は考慮していない）

#### エラーハンドリング
- 認証エラー: 401 Unauthorized
- 権限エラー: 403 Forbidden

---

### 2. 招待トークン検証（Invite Token Validation）

#### 目的
招待URLからアクセスした未登録ユーザーに、招待トークンの有効性とSchool情報を返す

#### 対象ユーザー
未認証ユーザー（招待URLを持つ）

#### 入力
- トークン（URLパラメータ: `/api/v1/invites/:token`）

#### 処理フロー
1. ユーザーが招待URLをブラウザで開く
2. フロントエンドが `GET /api/v1/invites/:token` にリクエスト送信
3. `Invites::Validator` サービスを呼び出し
   - トークンをHMAC-SHA256でハッシュ化
   - ハッシュ値（`token_digest`）でInviteレコードを検索
   - 有効性チェック:
     - `expires_at > 現在時刻`
     - `uses_count < max_uses`
4. 検証成功時、Inviteに紐づくSchool名を返却
5. フロントエンドが登録フォームを表示

#### 出力

**成功時（200 OK）:**
```json
{
  "school_name": "○○塾 本校"
}
```

**エラー:**
- 404 Not Found: トークン無効・期限切れ・使用済み

#### エッジケース
- 存在しないトークン → 404エラー
- 期限切れトークン → 404エラー
- 使用済みトークン（`uses_count >= max_uses`）→ 404エラー

#### エラーハンドリング
- トークンが無効: 404 Not Found

---

### 3. 講師登録（User Registration via Invite）

#### 目的
招待トークンを使用して新しい講師アカウントを作成する

#### 対象ユーザー
未認証ユーザー（有効な招待トークンを持つ）

#### 入力
- メールアドレス（必須）
- パスワード（必須、8文字以上）
- パスワード確認（必須）
- 名前（必須）
- 招待トークン（必須）

#### 処理フロー
1. ユーザーが登録フォームに情報を入力
2. フロントエンドでバリデーション実施
3. `POST /api/v1/auth` にリクエスト送信（devise_token_auth）
4. サーバー側でバリデーション実施
   - メールアドレス形式チェック
   - パスワード強度チェック（8文字以上）
   - 招待トークンの有効性チェック
5. メールアドレスの重複チェック
6. パスワードをbcryptでハッシュ化（cost=12、Rails default）
7. Userレコードをデータベースに保存
   - `school_id`: 招待トークンのSchool
   - `role`: teacher（招待経由はteacherのみ）
8. 招待トークンを消費（`invite.consume!` → `uses_count += 1`）
9. access-token/client/uidヘッダーを返却
10. ユーザーがログイン状態で登録完了

#### 出力

**成功時（201 Created）:**
```
Headers:
  access-token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
  client: abcd1234...
  uid: teacher@example.com

Body:
{
  "status": "success",
  "data": {
    "id": 123,
    "name": "山田太郎",
    "email": "teacher@example.com",
    "role": "teacher"
  }
}
```

**エラー:**
- 422 Unprocessable Entity: メールアドレス重複、パスワード不一致
- 404 Not Found: 招待トークン無効

#### エッジケース
- 既に登録済みのメールアドレス → 422エラー
- 招待トークンが登録中に期限切れになった場合 → 404エラー
- パスワード確認の不一致 → 422エラー

#### エラーハンドリング
- バリデーションエラー: 422 Unprocessable Entity
- 招待トークンエラー: 404 Not Found

---

### 4. ログイン（User Login）

#### 目的
登録済み講師がメールアドレスとパスワードでログインする

#### 対象ユーザー
登録済み講師

#### 入力
- メールアドレス（必須）
- パスワード（必須）

#### 処理フロー
1. ユーザーがログインフォームに情報を入力
2. `POST /api/v1/auth/sign_in` にリクエスト送信
3. devise_token_authがメールアドレスでUserを検索
4. パスワードをbcryptで検証
5. 検証成功時、トークン生成（access-token/client/uid）
6. トークンをレスポンスヘッダーで返却

#### 出力

**成功時（200 OK）:**
```
Headers:
  access-token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
  client: abcd1234...
  uid: teacher@example.com

Body:
{
  "data": {
    "id": 123,
    "name": "山田太郎",
    "email": "teacher@example.com",
    "role": "teacher"
  }
}
```

**エラー:**
- 401 Unauthorized: メールアドレスまたはパスワード不正

#### エッジケース
- 存在しないメールアドレス → 401エラー
- パスワード不一致 → 401エラー
- アカウントロック機能は未実装

#### エラーハンドリング
- 認証失敗: 401 Unauthorized

---

### 5. ログアウト（User Logout）

#### 目的
ログイン中の講師がセッションを終了する

#### 対象ユーザー
ログイン済み講師

#### 入力
- なし（認証ヘッダーから取得）

#### 処理フロー
1. ユーザーがログアウトをリクエスト
2. `DELETE /api/v1/auth/sign_out` にリクエスト送信（access-token/client/uidヘッダー付き）
3. devise_token_authがトークンを無効化
4. レスポンス返却

#### 出力

**成功時（200 OK）:**
```json
{
  "success": true
}
```

---

### 6. 生徒一覧取得（Students Index）

#### 目的
School内の生徒一覧をページネーション・フィルタリング付きで取得する

#### 対象ユーザー
ログイン済み講師（admin / teacher）

#### 入力
- `searchKeyword`（任意、生徒名部分一致検索）
- `school_stage`（任意、`elementary_school` / `junior_high_school` / `high_school`）
- `grade`（任意、学年フィルタ）
- `page`（任意、デフォルト: 1）
- `perPage`（任意、デフォルト: 20）

#### 処理フロー
1. `GET /api/v1/students` にリクエスト送信
2. 認証・認可チェック（`authenticate_user!`, `set_school!`）
3. `Students::IndexQuery` サービスを呼び出し
   - Schoolに所属する生徒を取得
   - フィルタリング適用（`searchKeyword`, `school_stage`, `grade`）
   - Kaminariでページネーション（デフォルト20件/ページ）
   - N+1問題回避（`includes(:class_subjects, :available_days, :teachers)`）
4. `Students::IndexResource` シリアライザでJSON整形（Alba使用）
5. レスポンス返却

#### 出力

**成功時（200 OK）:**
```json
{
  "students": [
    {
      "id": 1,
      "name": "佐藤花子",
      "school_stage": "junior_high_school",
      "grade": 2,
      "status": "active",
      "joined_on": "2024-04-01",
      "desired_school": "○○高校",
      "class_subjects": [
        {
          "id": 10,
          "name": "数学"
        }
      ],
      "teachers": [
        {
          "id": 5,
          "name": "山田先生"
        }
      ]
    }
  ],
  "meta": {
    "total_pages": 5,
    "total_count": 100,
    "current_page": 1,
    "per_page": 20
  }
}
```

#### エッジケース
- 検索結果が0件 → 空配列を返す
- ページ番号が範囲外 → 空配列を返す
- 無効な`school_stage` → フィルタリングをスキップ

#### エラーハンドリング
- 認証エラー: 401 Unauthorized

---

### 7. 生徒作成（Student Create）

#### 目的
新しい生徒をSchoolに登録する

#### 対象ユーザー
ログイン済み管理者（admin role）

#### 入力
- `name`（必須、最大50文字）
- `school_stage`（必須、`elementary_school` / `junior_high_school` / `high_school`）
- `grade`（必須、学年に応じた範囲: 小学校1-6、中高1-3）
- `joined_on`（必須、過去または当日の日付）
- `status`（任意、デフォルト: `active`）
- `desired_school`（任意、最大100文字）
- `subject_ids`（任意、配列）
- `available_day_ids`（任意、配列）
- `assignments`（任意、講師割り当て配列）

#### 処理フロー
1. `POST /api/v1/students` にリクエスト送信
2. 認証・認可チェック（`authenticate_user!`, `require_admin_role!`, `set_school!`）
3. `Students::CreateService` サービスを呼び出し
   - バリデーション実施
     - `grade_must_be_valid_for_stage`: 学年が学校段階に適合するか
     - `joined_on_cannot_be_future`: 入塾日が未来でないか
   - Studentレコード作成
   - 関連レコード作成（`subject_ids`, `available_day_ids`, `assignments`）
4. `Students::CreateResource` シリアライザでJSON整形
5. レスポンス返却

#### 出力

**成功時（201 Created）:**
```json
{
  "id": 1,
  "name": "佐藤花子",
  "school_stage": "junior_high_school",
  "grade": 2,
  "status": "active",
  "joined_on": "2024-04-01",
  "desired_school": "○○高校"
}
```

**エラー:**
- 422 Unprocessable Entity: バリデーションエラー
- 403 Forbidden: teacher roleのユーザー

#### エッジケース
- `grade`が`school_stage`に不適合（例: 小学校で学年7）→ 422エラー
- `joined_on`が未来日 → 422エラー
- 名前が50文字超過 → 422エラー

#### エラーハンドリング
- バリデーションエラー: 422 Unprocessable Entity
- 権限エラー: 403 Forbidden

---

### 8. 生徒更新（Student Update）

#### 目的
既存の生徒情報を更新する

#### 対象ユーザー
ログイン済み管理者（admin role）

#### 入力
- `id`（必須、生徒ID）
- 生徒作成と同じパラメータ

#### 処理フロー
1. `PATCH /api/v1/students/:id` にリクエスト送信
2. 認証・認可チェック
3. `Students::Updater` サービスを呼び出し
   - 生徒IDとSchoolでレコード検索
   - バリデーション実施
   - 関連レコード更新（upsert処理）
4. レスポンス返却

#### 出力

**成功時（200 OK）:**
```json
{
  "id": 1,
  "name": "佐藤花子",
  "school_stage": "junior_high_school",
  "grade": 3,
  "status": "active"
}
```

**エラー:**
- 404 Not Found: 生徒が見つからない
- 422 Unprocessable Entity: バリデーションエラー

---

### 9. 生徒削除（Student Delete）

#### 目的
生徒とその関連データ（授業記録）をSchoolから削除する

#### 対象ユーザー
ログイン済み管理者（admin role）

#### 入力
- `id`（必須、生徒ID）

#### 処理フロー
1. `DELETE /api/v1/students/:id` にリクエスト送信
2. 認証・認可チェック
3. `Students::Validator` で生徒を検証
4. `student.destroy!` 実行（cascade deleteで関連レコードも削除）
5. レスポンス返却

#### 出力

**成功時（204 No Content）:**
- レスポンスボディなし

**エラー:**
- 404 Not Found: 生徒が見つからない

---

### 10. 授業記録一覧取得（Lesson Notes Index）

#### 目的
School内の授業記録をフィルタリング・ページネーション付きで取得する

#### 対象ユーザー
ログイン済み講師（admin / teacher）

#### 入力
- `student_id`（任意、生徒IDフィルタ）
- `subject_id`（任意、科目IDフィルタ）
- `searchKeyword`（任意、タイトル・説明文の部分一致検索）
- `sortBy`（任意、ソート順: `expire_date_asc` / `expire_date_desc` 等）
- `page`（任意、デフォルト: 1）
- `perPage`（任意、デフォルト: 20）

#### 処理フロー
1. `GET /api/v1/lesson_notes` にリクエスト送信
2. 認証・認可チェック
3. `LessonNotes::IndexQuery` サービスを呼び出し
   - Schoolに所属する授業記録を取得
   - フィルタリング適用（`student_id`, `subject_id`, `searchKeyword`）
   - ソート適用（`sortBy`）
   - Kaminariでページネーション
4. `LessonNotes::IndexResource` シリアライザでJSON整形
5. レスポンス返却

#### 出力

**成功時（200 OK）:**
```json
{
  "lesson_notes": [
    {
      "id": 1,
      "title": "二次方程式の解法",
      "description": "因数分解と解の公式を学習",
      "note_type": "lesson",
      "expire_date": "2025-02-01",
      "created_by_name": "山田先生",
      "student": {
        "id": 1,
        "name": "佐藤花子"
      },
      "subject": {
        "id": 10,
        "name": "数学"
      }
    }
  ],
  "meta": {
    "total_pages": 3,
    "total_count": 50,
    "current_page": 1,
    "per_page": 20
  }
}
```

---

### 11. 授業記録作成（Lesson Note Create）

#### 目的
授業完了後に指導内容・宿題・次回予定を記録する

#### 対象ユーザー
ログイン済み講師（admin / teacher）

#### 入力
- `student_id`（必須）
- `subject_id`（必須）
- `title`（必須、最大50文字）
- `description`（任意、最大500文字）
- `note_type`（必須、`homework` / `lesson` / `other`）
- `expire_date`（必須、未来または当日の日付）

#### 処理フロー
1. `POST /api/v1/lesson_notes` にリクエスト送信
2. 認証・認可チェック
3. `LessonNotes::Validator` で生徒・科目の組み合わせ（`student_class_subject`）を検証
4. `LessonNotes::CreateService` サービスを呼び出し
   - バリデーション実施
     - `expire_date_cannot_be_in_the_past`: 期限日が過去でないか
   - LessonNoteレコード作成
     - `created_by_id`: 現在のユーザー
     - `created_by_name`: 現在のユーザー名（非正規化）
5. レスポンス返却

#### 出力

**成功時（201 Created）:**
```json
{
  "id": 1,
  "title": "二次方程式の解法",
  "description": "因数分解と解の公式を学習",
  "note_type": "lesson",
  "expire_date": "2025-02-01",
  "created_by_name": "山田先生"
}
```

**エラー:**
- 422 Unprocessable Entity: バリデーションエラー
- 404 Not Found: 生徒・科目の組み合わせが存在しない

#### エッジケース
- `expire_date`が過去日 → 422エラー
- タイトルが50文字超過 → 422エラー
- 説明文が500文字超過 → 422エラー

---

### 12. 授業記録更新（Lesson Note Update）

#### 目的
既存の授業記録を更新する

#### 対象ユーザー
ログイン済み講師（admin / teacher）

#### 入力
- `id`（必須、授業記録ID）
- 授業記録作成と同じパラメータ

#### 処理フロー
1. `PATCH /api/v1/lesson_notes/:id` にリクエスト送信
2. 認証・認可チェック
3. `LessonNotes::Updater` サービスを呼び出し
   - 授業記録IDで検索
   - バリデーション実施
   - 更新処理
     - `last_updated_by_id`: 現在のユーザー
     - `last_updated_by_name`: 現在のユーザー名
4. レスポンス返却

#### 出力

**成功時（200 OK）:**
```json
{
  "id": 1,
  "title": "二次方程式の解法（更新）",
  "last_updated_by_name": "鈴木先生"
}
```

---

### 13. 授業記録削除（Lesson Note Delete）

#### 目的
授業記録をSchoolから削除する

#### 対象ユーザー
ログイン済み管理者（admin role）

#### 入力
- `id`（必須、授業記録ID）

#### 処理フロー
1. `DELETE /api/v1/lesson_notes/:id` にリクエスト送信
2. 認証・認可チェック（`require_admin_role!`）
3. `LessonNote.find(params[:id])` で検索
4. `lesson_note.destroy!` 実行
5. レスポンス返却

#### 出力

**成功時（204 No Content）:**
- レスポンスボディなし

**エラー:**
- 404 Not Found: 授業記録が見つからない
- 403 Forbidden: teacher roleのユーザー

---

### 14. 科目一覧取得（Class Subjects Index）

#### 目的
School内の科目一覧を取得する

#### 対象ユーザー
ログイン済み講師（admin / teacher）

#### 入力
- なし（認証情報からSchoolを特定）

#### 処理フロー
1. `GET /api/v1/class_subjects` にリクエスト送信
2. 認証チェック（`authenticate_user!`）
3. ユーザーの所属Schoolを取得（`set_school!`）
4. `ClassSubjects::IndexQuery` サービスを呼び出し
   - Schoolに所属する科目を取得（`@school.class_subjects.order(id: :asc)`）
5. `ClassSubjects::IndexResource` シリアライザでJSON整形
6. レスポンス返却

#### 出力

**成功時（200 OK）:**
```json
{
  "class_subjects": [
    {
      "id": 1,
      "name": "数学"
    },
    {
      "id": 2,
      "name": "英語"
    },
    {
      "id": 3,
      "name": "国語"
    }
  ]
}
```

**エラー:**
- 401 Unauthorized: 未認証

#### エッジケース
- 科目が1つも登録されていない場合 → 空配列を返却（`{ "class_subjects": [] }`）

#### エラーハンドリング
- 認証エラー: 401 Unauthorized

---

### 15. 科目作成（Class Subject Create）

#### 目的
新しい科目をSchoolに追加する

#### 対象ユーザー
ログイン済み管理者（admin role）

#### 入力
- `name`（必須、文字列、1-50文字）

#### 処理フロー
1. `POST /api/v1/class_subjects` にリクエスト送信
2. 認証・認可チェック（`require_admin_role!`）
3. ユーザーの所属Schoolを取得（`set_school!`）
4. `ClassSubjects::CreateService` サービスを呼び出し
   - Strong Parametersでnameを許可
   - `@school.class_subjects.create!(name: params[:name])`
5. バリデーション実行（name必須、1-50文字、School内で一意）
6. `ClassSubjects::ShowResource` シリアライザでJSON整形
7. レスポンス返却

#### 出力

**成功時（201 Created）:**
```json
{
  "id": 4,
  "name": "理科"
}
```

**エラー:**
- 422 Unprocessable Entity: バリデーションエラー
  ```json
  {
    "status": "error",
    "errors": {
      "name": ["has already been taken"]
    }
  }
  ```
- 403 Forbidden: teacher roleのユーザー

#### エッジケース
- 同じ名前の科目が既に存在する場合 → 422エラー（uniqueness validation）
- 空文字列や50文字超過 → 422エラー

#### エラーハンドリング
- バリデーションエラー: 422 Unprocessable Entity
- 権限エラー: 403 Forbidden

---

### 16. 科目更新（Class Subject Update）

#### 目的
既存の科目名を変更する

#### 対象ユーザー
ログイン済み管理者（admin role）

#### 入力
- `id`（必須、科目ID）
- `name`（必須、文字列、1-50文字）

#### 処理フロー
1. `PATCH /api/v1/class_subjects/:id` にリクエスト送信
2. 認証・認可チェック（`require_admin_role!`）
3. ユーザーの所属Schoolを取得（`set_school!`）
4. `@school.class_subjects.find(params[:id])` で検索
5. `ClassSubjects::UpdateService` サービスを呼び出し
   - Strong Parametersでnameを許可
   - `class_subject.update!(name: params[:name])`
6. バリデーション実行
7. `ClassSubjects::ShowResource` シリアライザでJSON整形
8. レスポンス返却

#### 出力

**成功時（200 OK）:**
```json
{
  "id": 4,
  "name": "物理"
}
```

**エラー:**
- 404 Not Found: 科目が見つからない
- 422 Unprocessable Entity: バリデーションエラー
- 403 Forbidden: teacher roleのユーザー

#### エッジケース
- 変更後の名前が既存の科目と重複する場合 → 422エラー

#### エラーハンドリング
- リソース不存在: 404 Not Found
- バリデーションエラー: 422 Unprocessable Entity
- 権限エラー: 403 Forbidden

---

### 17. 科目削除（Class Subject Delete）

#### 目的
科目をSchoolから削除する

#### 対象ユーザー
ログイン済み管理者（admin role）

#### 入力
- `id`（必須、科目ID）

#### 処理フロー
1. `DELETE /api/v1/class_subjects/:id` にリクエスト送信
2. 認証・認可チェック（`require_admin_role!`）
3. ユーザーの所属Schoolを取得（`set_school!`）
4. `@school.class_subjects.find(params[:id])` で検索
5. 関連する授業記録の確認
   - `class_subject.student_class_subjects.exists?` をチェック
   - 授業記録が存在する場合は削除を拒否（422エラー）
6. 授業記録が存在しない場合のみ削除実行
7. `class_subject.destroy!` 実行
8. レスポンス返却

#### 出力

**成功時（204 No Content）:**
- レスポンスボディなし

**エラー:**
- 404 Not Found: 科目が見つからない
- 422 Unprocessable Entity: 削除不可（授業記録が存在）
  ```json
  {
    "status": "error",
    "errors": {
      "base": ["Cannot delete class subject with existing lesson notes"]
    }
  }
  ```
- 403 Forbidden: teacher roleのユーザー

#### エッジケース
- 授業記録が紐づいている科目を削除しようとした場合 → 422エラーで拒否（データ整合性保護）
- 授業記録が存在しない科目 → 正常に削除

#### エラーハンドリング
- リソース不存在: 404 Not Found
- 削除制約違反: 422 Unprocessable Entity
- 権限エラー: 403 Forbidden

---

## API設計

### 認証方式

**devise_token_auth によるトークンベース認証:**

すべての保護されたエンドポイントでHTTPヘッダーによる認証を実施:

```
access-token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
client: abcd1234...
uid: teacher@example.com
```

- トークン有効期限: 24時間
- セッションタイムアウト: 30分無操作

---

### エンドポイント一覧

| メソッド | パス | 認証 | 権限 | 説明 |
|---------|------|------|------|------|
| **認証・招待** |
| POST | `/api/v1/invites` | 必須 | admin | 招待トークン生成 |
| GET | `/api/v1/invites/:token` | 不要 | - | 招待トークン検証 |
| POST | `/api/v1/auth` | 不要 | - | ユーザー登録 |
| POST | `/api/v1/auth/sign_in` | 不要 | - | ログイン |
| DELETE | `/api/v1/auth/sign_out` | 必須 | - | ログアウト |
| **生徒管理** |
| GET | `/api/v1/students` | 必須 | admin/teacher | 生徒一覧取得 |
| POST | `/api/v1/students` | 必須 | admin | 生徒作成 |
| PATCH | `/api/v1/students/:id` | 必須 | admin | 生徒更新 |
| DELETE | `/api/v1/students/:id` | 必須 | admin | 生徒削除 |
| **授業記録管理** |
| GET | `/api/v1/lesson_notes` | 必須 | admin/teacher | 授業記録一覧取得 |
| POST | `/api/v1/lesson_notes` | 必須 | admin/teacher | 授業記録作成 |
| PATCH | `/api/v1/lesson_notes/:id` | 必須 | admin/teacher | 授業記録更新 |
| DELETE | `/api/v1/lesson_notes/:id` | 必須 | admin | 授業記録削除 |
| **科目管理** |
| GET | `/api/v1/class_subjects` | 必須 | admin/teacher | 科目一覧取得 |
| POST | `/api/v1/class_subjects` | 必須 | admin | 科目作成 |
| PATCH | `/api/v1/class_subjects/:id` | 必須 | admin | 科目更新 |
| DELETE | `/api/v1/class_subjects/:id` | 必須 | admin | 科目削除 |

---

### レスポンス形式

#### 成功レスポンス

**単一リソース取得・作成・更新:**
```json
{
  "id": 1,
  "name": "佐藤花子",
  "school_stage": "junior_high_school",
  "grade": 2
}
```

**リスト取得（ページネーション付き）:**
```json
{
  "students": [...],
  "meta": {
    "total_pages": 5,
    "total_count": 100,
    "current_page": 1,
    "per_page": 20
  }
}
```

#### エラーレスポンス

**バリデーションエラー（422 Unprocessable Entity）:**
```json
{
  "status": "error",
  "errors": {
    "email": ["has already been taken"],
    "password": ["is too short (minimum is 8 characters)"]
  }
}
```

**認証エラー（401 Unauthorized）:**
```json
{
  "errors": ["You need to sign in or sign up before continuing."]
}
```

**権限エラー（403 Forbidden）:**
```json
{
  "error": "Forbidden"
}
```

**リソース不存在（404 Not Found）:**
```json
{
  "error": "Record not found"
}
```

---

## データフロー

```
[クライアント（フロントエンド）]
  ↓ HTTPリクエスト（JSON）
[ルーター（config/routes.rb）]
  ↓ ルーティング
[ミドルウェア（Rack::Cors）]
  ↓ CORS検証
[コントローラー（app/controllers/api/v1/*）]
  ↓ before_action
[認証（devise_token_auth）]
  ↓ authenticate_user!
[認可（Concerns::RequireAdminRole）]
  ↓ require_admin_role!
[サービス層（app/services/*）]
  ↓ ビジネスロジック実行
[モデル層（app/models/*）]
  ↓ バリデーション・永続化
[データベース（PostgreSQL）]
  ↓ データ取得/保存
[シリアライザ（app/serializers/*）]
  ↓ JSON整形（Alba）
[レスポンス返却]
  ↓
[クライアント（フロントエンド）]
```

---

## バリデーション仕様

### User（講師）

| フィールド | 型 | 必須 | 制約 | エラーメッセージ |
|-----------|-----|------|------|------------------|
| name | string | ○ | 1-50文字 | Name is required |
| email | string | ○ | メール形式、一意 | Email has already been taken |
| password | string | ○ | 8文字以上 | Password is too short (minimum is 8 characters) |
| role | enum | ○ | `admin` または `teacher` | Role is required |

### Student（生徒）

| フィールド | 型 | 必須 | 制約 | エラーメッセージ |
|-----------|-----|------|------|------------------|
| name | string | ○ | 1-50文字 | Name is required |
| school_stage | enum | ○ | `elementary_school` / `junior_high_school` / `high_school` | School stage is required |
| grade | integer | ○ | 学校段階に応じた範囲（小1-6、中高1-3） | Grade must be valid for stage |
| joined_on | date | ○ | 過去または当日 | Joined on cannot be in the future |
| status | enum | ○ | `active` / `inactive` / `on_leave` / `graduated` | Status is required |
| desired_school | string | × | 最大100文字 | - |

### LessonNote（授業記録）

| フィールド | 型 | 必須 | 制約 | エラーメッセージ |
|-----------|-----|------|------|------------------|
| title | string | ○ | 1-50文字 | Title is required |
| description | text | × | 最大500文字 | Description is too long (maximum is 500 characters) |
| note_type | enum | ○ | `homework` / `lesson` / `other` | Note type is required |
| expire_date | date | ○ | 未来または当日 | Expire date must not be in the past |
| student_class_subject_id | bigint | ○ | 存在するレコード | Student class subject not found |

### Invite（招待トークン）

| フィールド | 型 | 必須 | 制約 | エラーメッセージ |
|-----------|-----|------|------|------------------|
| token_digest | string | ○ | HMAC-SHA256ハッシュ、一意 | - |
| school_id | bigint | ○ | 存在するSchool | - |
| expires_at | datetime | ○ | 未来の日時（生成時+7日） | - |
| max_uses | integer | ○ | デフォルト1 | - |
| uses_count | integer | ○ | デフォルト0 | - |

---

## セキュリティ考慮事項

### 認証・認可

- **devise_token_auth認証:** すべての保護されたエンドポイントでトークン検証
- **トークン有効期限:** 24時間（`config.token_lifespan`）
- **ロールベースアクセス制御（RBAC）:**
  - `admin`: 全操作可能（生徒・授業記録のCRUD、招待トークン生成、削除操作）
  - `teacher`: 読み取りと作成・更新のみ（削除は不可）
- **所有権チェック:** ユーザーは自分のSchoolのリソースのみアクセス可能（`set_school!`）

### 入力値検証

- **Strong Parameters:** Railsの`params.permit`で許可されたパラメータのみ受け入れ
- **サーバー側での必須検証:** クライアント側のバリデーションは回避可能なため、サーバー側で必ず検証
- **型チェック:** ActiveRecordのバリデーションで型と範囲を検証
- **カスタムバリデーション:**
  - `grade_must_be_valid_for_stage`: 学年が学校段階に適合するか
  - `joined_on_cannot_be_future`: 入塾日が未来でないか
  - `expire_date_cannot_be_in_the_past`: 期限日が過去でないか

### XSS対策

- **出力エスケープ:** フロントエンドでユーザー入力を表示する際は必ずエスケープ
- **Content Security Policy (CSP):** CloudFrontでCSPヘッダーを設定
- **サニタイゼーション:** `description`フィールド等のテキスト入力は最大文字数制限

### CSRF対策

- **トークンベース認証:** CSRFトークンは不要（ステートレス認証のため）
- **CORS設定:** `config/initializers/cors.rb`でオリジン制限

### SQLインジェクション対策

- **パラメータ化クエリ:** ActiveRecordのプレースホルダーを使用
- **生SQLの禁止:** 可能な限りORMを使用、生SQLは避ける

### レート制限

- **現状未実装:** 将来的にRack::Attackで実装予定
  - ログイン・登録: 1分間に5回まで
  - API全般: 1時間に1000リクエストまで

### データ保護

- **パスワードハッシュ化:** bcrypt（cost=12、Rails default）
- **招待トークン:** HMAC-SHA256でハッシュ化（生トークンはDBに保存しない）
- **HTTPS強制:** すべての通信をHTTPS経由で行う（ALBでHTTP→HTTPSリダイレクト）
- **センシティブデータのログ除外:** `config/initializers/filter_parameter_logging.rb`でパスワード・トークンをフィルタ

---

## パフォーマンス最適化

### N+1クエリ対策

- **Bulletによる検出:** 開発環境でN+1クエリを自動検出・警告
- **Eager Loading:**
  - `Students::IndexQuery`: `includes(:class_subjects, :available_days, :teachers)`
  - `LessonNotes::IndexQuery`: `includes(:student_class_subject, :created_by)`

### クエリ最適化

- **Queryオブジェクトパターン:** 複雑な検索ロジックを`app/queries/*`に分離
- **インデックス:**
  - `students`: `school_id`
  - `lesson_notes`: `student_class_subject_id`, `expire_date`, `note_type`
  - `invites`: `token_digest`（UNIQUE）

### ページネーション

- **Kaminari:** すべてのリスト取得APIでページネーション実装（デフォルト20件/ページ）

### キャッシュ戦略

- **現状未実装:** 将来的にRails.cacheで実装予定
  - 科目一覧（頻繁に変更されない）
  - School情報（頻繁に変更されない）
