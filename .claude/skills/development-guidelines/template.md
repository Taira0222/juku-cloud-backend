# 開発ガイドライン

## 概要

このドキュメントは、開発チーム全体で遵守すべきコーディング規約、開発フロー、ベストプラクティスを定義します。

## 開発環境セットアップ

### 必須ツール（Rails API）
- Ruby: 3.3.x
- Bundler: 最新版
- PostgreSQL: 14.x以上
- Redis: 7.x以上
- Git: 最新版

### 推奨ツール
- VSCode (推奨エディタ)
- 推奨VSCode拡張機能（Rails）:
  - Ruby
  - Ruby Solargraph
  - ERB Formatter/Beautify
  - Rails
  - Docker (Dockerを使用する場合)

### セットアップ手順（Rails API）
```bash
# リポジトリクローン
git clone <repository-url>
cd juku-cloud-backend

# Rubyバージョン確認
ruby -v  # 3.3.x であることを確認

# 依存関係インストール
bundle install

# 環境変数設定
cp .env.example .env
# .env ファイルを編集してデータベース接続情報などを設定

# データベースセットアップ
bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rails db:seed

# テスト実行
bundle exec rspec

# 開発サーバー起動
bundle exec rails server
```

### セットアップ手順（フロントエンド - オプション）
```bash
# Node.js環境のセットアップ
# 必須ツール
- Node.js: v20.x以上
- npm/pnpm: 最新版

# 依存関係インストール
npm install

# 環境変数設定
cp .env.example .env

# 開発サーバー起動
npm run dev
```

## コーディング規約

### Ruby/Rails

#### スタイルガイド
- [Ruby Style Guide](https://rubystyle.guide/)に準拠
- [Rails Style Guide](https://rails.rubystyle.guide/)に準拠
- RuboCopで自動チェック

#### 基本スタイル
```ruby
# Good: シンプルで読みやすい
class UserService
  def self.create(params:)
    user = User.new(params)

    if user.save
      UserMailer.welcome_email(user).deliver_later
      Result.success(user: user)
    else
      Result.failure(errors: user.errors.full_messages)
    end
  end
end

# Bad: コントローラーにビジネスロジック
class UsersController < ApplicationController
  def create
    @user = User.new(user_params)
    if @user.save
      UserMailer.welcome_email(@user).deliver_later
      render json: @user
    else
      render json: { errors: @user.errors }
    end
  end
end
```

#### Railsベストプラクティス
- **Fat Modelを避ける:** ビジネスロジックはService層に配置
- **コントローラーはシンプルに:** リクエスト/レスポンス処理のみ
- **N+1問題を回避:** `includes`, `preload`, `eager_load`を活用
- **Strong Parameters:** 必ず使用

```ruby
# Good: N+1問題を回避
users = User.includes(:lessons, :grade_records).all

# Bad: N+1問題
users = User.all
users.each do |user|
  puts user.lessons.count
end
```

### TypeScript（フロントエンド）

#### 型定義
- `any` の使用を避ける
- 明示的な型アノテーションを優先する
- インターフェースと型エイリアスを適切に使い分ける

```typescript
// Good
interface User {
  id: string;
  name: string;
  email: string;
}

// Bad
const user: any = { ... };
```

### 命名規則

#### Ruby/Rails
- **変数・メソッド:** `snake_case`
- **クラス・モジュール:** `PascalCase`
- **定数:** `UPPER_SNAKE_CASE`
- **真偽値メソッド:** `?`で終わる（例: `active?`, `valid?`）
- **破壊的メソッド:** `!`で終わる（例: `save!`, `update!`）

```ruby
# Good
class UserService
  MAX_RETRY_COUNT = 3

  def create_user(name:, email:)
    user = User.new(name: name, email: email)
    user.save!
  end

  def active?
    status == 'active'
  end
end

# Bad
class userService
  def CreateUser(name, email)
    User.new(:name => name, :email => email)  # 古いハッシュ記法
  end
end
```

#### TypeScript
- **変数・関数:** `camelCase`
- **クラス・インターフェース:** `PascalCase`
- **定数:** `UPPER_SNAKE_CASE`
- **真偽値:** `is`, `has`, `should`で始める
- **配列:** 複数形にする

```typescript
const userName = 'John';
const isActive = true;
const hasPermission = false;
const userList = [];
```

#### クラス・インターフェース
- `PascalCase` を使用
- インターフェース名にプレフィックスを付けない（`IUser` ではなく `User`）

```typescript
class UserService {}
interface User {}
type UserRole = 'admin' | 'user';
```

#### 定数
- `UPPER_SNAKE_CASE` を使用

```typescript
const MAX_RETRY_COUNT = 3;
const API_BASE_URL = 'https://api.example.com';
```

### ファイル構成

#### インポート順序
1. 外部ライブラリ
2. 内部モジュール（絶対パス）
3. 相対パス
4. 型定義のみのインポート

```typescript
import express from 'express';
import { UserService } from '@/application/services/UserService';
import { validateInput } from './utils';
import type { User } from '@/domain/entities/User';
```

#### エクスポート
- Named export を優先する（Default export は避ける）

```typescript
// Good
export const UserService = () => {};

// Bad
export default () => {};
```

### コメント

#### ドキュメントコメント
- 公開API、複雑なロジックにはJSDocを記述

```typescript
/**
 * ユーザーを作成する
 * @param name - ユーザー名
 * @param email - メールアドレス
 * @returns 作成されたユーザー
 * @throws {ValidationError} 入力値が不正な場合
 */
export const createUser = async (name: string, email: string): Promise<User> => {
  // ...
};
```

#### インラインコメント
- WHYを説明する（WHATは説明しない）
- 複雑なロジックの意図を明確にする

```typescript
// Good: 理由を説明
// 同時実行を防ぐためにロックを取得
await acquireLock(userId);

// Bad: コードを繰り返しているだけ
// ユーザーIDを取得
const userId = user.id;
```

## Git ワークフロー

### ブランチ戦略

```
main          # 本番環境
  └─ develop  # 開発環境
       └─ feature/xxx   # 機能開発
       └─ bugfix/xxx    # バグ修正
       └─ hotfix/xxx    # 緊急修正
```

### ブランチ命名規則
- `feature/[issue-number]-short-description`
- `bugfix/[issue-number]-short-description`
- `hotfix/[issue-number]-short-description`

例: `feature/123-user-authentication`

### コミットメッセージ

#### フォーマット
```
<type>(<scope>): <subject>

<body>

<footer>
```

#### Type
- `feat`: 新機能
- `fix`: バグ修正
- `docs`: ドキュメント変更
- `style`: コードフォーマット（機能に影響なし）
- `refactor`: リファクタリング
- `test`: テスト追加・修正
- `chore`: ビルド・ツール設定変更

#### 例
```
feat(auth): ユーザー認証機能を追加

- JWT認証を実装
- ログイン/ログアウトエンドポイントを追加
- 認証ミドルウェアを実装

Closes #123
```

### プルリクエスト

#### タイトル
- コミットメッセージと同じフォーマット

#### 説明テンプレート
```markdown
## 概要
変更内容の概要

## 変更内容
- 変更点1
- 変更点2

## テスト
- [ ] ユニットテスト追加
- [ ] 手動テスト実施

## スクリーンショット（必要な場合）

## 関連Issue
Closes #123
```

#### レビュー基準
- コードが要件を満たしているか
- テストが十分にカバーされているか
- コーディング規約に準拠しているか
- セキュリティ上の問題がないか
- パフォーマンス上の問題がないか

## テスト

### テスト戦略
- ユニットテスト: 関数・クラス単位
- 統合テスト: モジュール間の連携
- E2Eテスト: ユーザーシナリオ

### テストカバレッジ目標
- 全体: 80%以上
- クリティカルパス: 100%

### テスト命名規則
```typescript
describe('UserService', () => {
  describe('createUser', () => {
    it('should create a new user with valid input', () => {
      // ...
    });

    it('should throw ValidationError with invalid email', () => {
      // ...
    });
  });
});
```

### テストのベストプラクティス
- AAA パターン (Arrange, Act, Assert) を使用
- 1テスト1アサーション（可能な限り）
- テストは独立させる（他のテストに依存しない）

## エラーハンドリング

### カスタムエラークラス
```typescript
export class ValidationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'ValidationError';
  }
}
```

### エラーレスポンス
```typescript
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input",
    "details": [
      {
        "field": "email",
        "message": "Invalid email format"
      }
    ]
  }
}
```

## セキュリティ

### 入力値検証
- すべてのユーザー入力を検証する
- ホワイトリスト方式を採用する

### 認証・認可
- パスワードはハッシュ化して保存
- JWT トークンは短い有効期限を設定
- センシティブな操作には追加の認証を要求

### 機密情報管理
- 環境変数で管理
- コードに直接記述しない
- Git にコミットしない

## パフォーマンス

### データベース
- N+1 問題を避ける
- 適切なインデックスを設定
- クエリを最適化する

### API
- ページネーションを実装
- レスポンスをキャッシュする
- 不要なデータを返さない

## デプロイメント

### デプロイフロー
1. develop ブランチにマージ → 開発環境に自動デプロイ
2. main ブランチにマージ → 本番環境にデプロイ（手動承認）

### デプロイ前チェックリスト
- [ ] すべてのテストが通過
- [ ] コードレビュー完了
- [ ] マイグレーションスクリプト確認
- [ ] 環境変数設定確認
- [ ] ロールバック手順確認

## ドキュメント

### 必須ドキュメント
- README.md: プロジェクト概要とセットアップ手順
- API仕様書: OpenAPI/Swagger
- 各種設計書: docs/ ディレクトリ内

### ドキュメント更新タイミング
- 機能追加時
- 仕様変更時
- セットアップ手順変更時

## コードレビューガイドライン

### レビュアーの責任
- 24時間以内にレビュー開始
- 建設的なフィードバックを提供
- コードだけでなく、設計も確認

### レビュー観点
1. 機能性: 要件を満たしているか
2. 可読性: コードが理解しやすいか
3. 保守性: 変更・拡張しやすいか
4. テスト: 十分にテストされているか
5. セキュリティ: 脆弱性がないか
6. パフォーマンス: 効率的か

## 禁止事項

### コード
- `console.log` を本番コードに含めない
- `any` 型の乱用
- ハードコーディング（マジックナンバー、URL等）
- グローバル変数の使用

### Git
- 直接 main/develop ブランチへのプッシュ
- 大量の変更を含む単一コミット
- 意味のないコミットメッセージ

## トラブルシューティング

### よくある問題と解決方法

#### 問題: npm install が失敗する
```bash
# node_modules と package-lock.json を削除して再インストール
rm -rf node_modules package-lock.json
npm install
```

#### 問題: TypeScript のコンパイルエラー
```bash
# 型定義キャッシュをクリア
rm -rf node_modules/.cache
npm run build
```
