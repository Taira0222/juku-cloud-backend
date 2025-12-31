# 開発ガイドライン作成ガイド

## 開発ガイドラインの目的

開発ガイドラインは、チーム全体でコードの品質と一貫性を保つための共通ルールです。新しいメンバーが参加した際のオンボーディング資料としても機能します。

## 作成時の原則

### 1. 実践可能なルールを定義する

理想論ではなく、実際に守れるルールを定義します。

**良い例:**
- 関数は50行以内に収める
- PR作成から24時間以内にレビューを開始する

**悪い例:**
- すべてのコードを完璧にする
- できるだけ早くレビューする

### 2. 自動化できるルールは自動化する

Linter、Formatter、CI/CDで強制できるルールは、ドキュメントに書くだけでなく自動化します。

**自動化できるもの:**
- コードフォーマット（Prettier）
- コーディング規約（ESLint）
- テストカバレッジチェック
- 型チェック（TypeScript）

### 3. 具体的な例を示す

Good/Badの例を必ず含めます。

## セクションごとのガイド

### コーディング規約

#### Ruby/Rails

**必ず含めるべき項目:**
- Rubyスタイルガイドへの準拠
- Railsベストプラクティス
- サービス層の使い方
- N+1問題の回避

**例:**
```ruby
# Good: シンプルで読みやすいコード
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
      UserStatistics.update_for_user(@user)
      render json: @user
    else
      render json: { errors: @user.errors }, status: :unprocessable_entity
    end
  end
end

# Good: N+1問題を回避
users = User.includes(:lessons, :grade_records).all

# Bad: N+1問題
users = User.all
users.each do |user|
  user.lessons.each { |lesson| puts lesson.title }
end

# Good: ガード節を使用
def process_user(user)
  return unless user.active?
  return if user.lessons.empty?

  user.lessons.each { |lesson| process_lesson(lesson) }
end

# Bad: ネストが深い
def process_user(user)
  if user.active?
    if !user.lessons.empty?
      user.lessons.each { |lesson| process_lesson(lesson) }
    end
  end
end
```

#### TypeScript

**必ず含めるべき項目:**
- `any`型の使用ポリシー
- null/undefinedのハンドリング方法
- 型定義の方針（interface vs type）
- Genericの使用方法

**例:**
```typescript
// Good: 明示的な型定義
interface User {
  id: string;
  name: string;
  email: string;
  createdAt: Date;
}

// Bad: anyを使用
const user: any = fetchUser();

// Good: Optional Chaining
const userName = user?.profile?.name ?? 'Guest';

// Bad: 冗長なチェック
const userName = user && user.profile && user.profile.name ? user.profile.name : 'Guest';
```

#### 命名規則

**チェックリスト:**
- [ ] 変数名の規則（camelCase, snake_case等）
- [ ] 定数名の規則（UPPER_SNAKE_CASE等）
- [ ] クラス名の規則（PascalCase等）
- [ ] ファイル名の規則
- [ ] 真偽値の命名規則（is/has/shouldプレフィックス）
- [ ] 配列・リストの命名規則（複数形）

### Git ワークフロー

#### ブランチ戦略

プロジェクトの規模に応じて選択:

**小規模プロジェクト（GitHub Flow）:**
```
main
  └─ feature/xxx
```

**中〜大規模プロジェクト（Git Flow）:**
```
main
  └─ develop
       └─ feature/xxx
       └─ bugfix/xxx
       └─ hotfix/xxx
```

#### コミットメッセージ

**Conventional Commits を推奨:**
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Type の定義:**
- `feat`: 新機能
- `fix`: バグ修正
- `docs`: ドキュメント
- `style`: フォーマット（コード動作に影響なし）
- `refactor`: リファクタリング
- `test`: テスト
- `chore`: ビルド・設定変更

**良い例:**
```
feat(auth): JWT認証を実装

- トークン生成・検証機能を追加
- 認証ミドルウェアを実装
- リフレッシュトークン機能を追加

Closes #123
```

**悪い例:**
```
update
```

### テスト

#### テストカバレッジの目標設定

現実的な目標を設定:

- **全体**: 70-80%
- **クリティカルパス**: 100%
- **ユーティリティ関数**: 90%以上
- **UI コンポーネント**: 60%以上

#### テスト命名規則

**推奨パターン:**
```typescript
describe('[対象]', () => {
  describe('[メソッド/機能]', () => {
    it('should [期待される動作] when [条件]', () => {
      // テストコード
    });
  });
});
```

**例:**
```typescript
describe('UserService', () => {
  describe('createUser', () => {
    it('should create a user when valid data is provided', () => {
      // Arrange
      const userData = { name: 'John', email: 'john@example.com' };

      // Act
      const result = userService.createUser(userData);

      // Assert
      expect(result).toBeDefined();
      expect(result.name).toBe('John');
    });

    it('should throw ValidationError when email is invalid', () => {
      const userData = { name: 'John', email: 'invalid' };

      expect(() => userService.createUser(userData))
        .toThrow(ValidationError);
    });
  });
});
```

### セキュリティ

#### OWASP Top 10 への対策

各脅威に対する具体的な対策を記載:

1. **Injection（SQLインジェクション等）**
   - ORM/パラメータ化クエリを使用
   - 入力値検証の徹底

2. **Broken Authentication（認証の不備）**
   - 強力なパスワードポリシー
   - MFA（多要素認証）の実装
   - セッションタイムアウトの設定

3. **Sensitive Data Exposure（機密データの露出）**
   - HTTPS通信の強制
   - パスワードのハッシュ化（bcrypt等）
   - 環境変数での機密情報管理

4. **XSS（クロスサイトスクリプティング）**
   - 出力時のエスケープ処理
   - Content Security Policy (CSP) の設定

5. **Broken Access Control（アクセス制御の不備）**
   - 認可チェックの徹底
   - 最小権限の原則

#### 入力値検証

**クライアント側とサーバー側の両方で検証:**
```typescript
// クライアント側（UX向上）
const validateEmail = (email: string): boolean => {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
};

// サーバー側（セキュリティ）
import { z } from 'zod';

const userSchema = z.object({
  name: z.string().min(1).max(100),
  email: z.string().email(),
  age: z.number().int().min(0).max(120).optional(),
});

// バリデーション実行
const result = userSchema.safeParse(userData);
if (!result.success) {
  throw new ValidationError(result.error.message);
}
```

### パフォーマンス

#### データベース最適化

**N+1問題の回避:**
```typescript
// Bad: N+1問題
const users = await User.findAll();
for (const user of users) {
  user.posts = await Post.findAll({ where: { userId: user.id } });
}

// Good: JOIN または Eager Loading
const users = await User.findAll({
  include: [Post]
});
```

**インデックスの設定:**
```sql
-- 頻繁に検索されるカラムにインデックス
CREATE INDEX idx_users_email ON users(email);

-- 複合インデックス
CREATE INDEX idx_posts_user_created ON posts(user_id, created_at);
```

#### API最適化

**ページネーション:**
```typescript
// Bad: すべてのデータを返す
const users = await User.findAll();

// Good: ページネーション
const users = await User.findAll({
  limit: 20,
  offset: (page - 1) * 20,
});
```

**レスポンスキャッシュ:**
```typescript
import { cache } from '@/infrastructure/cache';

export const getUsers = async (): Promise<User[]> => {
  const cacheKey = 'users:all';

  // キャッシュチェック
  const cached = await cache.get(cacheKey);
  if (cached) return JSON.parse(cached);

  // データ取得
  const users = await User.findAll();

  // キャッシュ保存（5分間）
  await cache.set(cacheKey, JSON.stringify(users), 300);

  return users;
};
```

### コードレビュー

#### レビューのチェックリスト

**機能性:**
- [ ] 要件を満たしているか
- [ ] エッジケースが考慮されているか
- [ ] エラーハンドリングが適切か

**コード品質:**
- [ ] コーディング規約に準拠しているか
- [ ] 重複コードがないか
- [ ] 適切に抽象化されているか
- [ ] 命名が適切か

**テスト:**
- [ ] ユニットテストが追加されているか
- [ ] テストカバレッジが十分か
- [ ] テストが適切に命名されているか

**セキュリティ:**
- [ ] 入力値検証が行われているか
- [ ] 認証・認可が適切か
- [ ] 機密情報が露出していないか

**パフォーマンス:**
- [ ] N+1問題がないか
- [ ] 不要なループがないか
- [ ] 適切にキャッシュされているか

#### レビューコメントの書き方

**建設的なフィードバック:**
```
// Good
「この部分は○○の理由で△△に変更することを推奨します。
例: function名をcalculateTotalからgetTotalに変更すると、
副作用がないことが明確になります。」

// Bad
「これは間違っています。」
```

**質問形式:**
```
// Good
「この実装だと○○の場合に問題が起きる可能性がありますが、
△△のケースは考慮されていますか?」

// Bad
「これはバグです。」
```

## 自動化の設定例

### RuboCop設定（Ruby/Rails）

```yaml
# .rubocop.yml
AllCops:
  NewCops: enable
  TargetRubyVersion: 3.3
  Exclude:
    - 'db/schema.rb'
    - 'bin/**/*'
    - 'vendor/**/*'
    - 'node_modules/**/*'

# ドキュメントコメントを強制しない
Style/Documentation:
  Enabled: false

# メソッドの長さ制限
Metrics/MethodLength:
  Max: 20
  Exclude:
    - 'db/migrate/**/*'

# ABC メトリック（複雑度）
Metrics/AbcSize:
  Max: 20

# ブロックの長さ制限
Metrics/BlockLength:
  Max: 25
  Exclude:
    - 'spec/**/*'
    - 'config/routes.rb'

# 文字列リテラルは frozen_string_literal を使用
Style/FrozenStringLiteralComment:
  Enabled: true

# Rails 固有の設定
Rails:
  Enabled: true

Rails/SkipsModelValidations:
  Enabled: true
  Exclude:
    - 'db/migrate/**/*'
```

### Brakeman設定（セキュリティスキャン）

```yaml
# config/brakeman.yml
:skip_checks:
# 必要に応じて特定のチェックをスキップ

:report_progress: true
:quiet: false
```

### SimpleCov設定（テストカバレッジ）

```ruby
# spec/spec_helper.rb
require 'simplecov'

SimpleCov.start 'rails' do
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/vendor/'

  add_group 'Controllers', 'app/controllers'
  add_group 'Models', 'app/models'
  add_group 'Services', 'app/services'
  add_group 'Queries', 'app/queries'
  add_group 'Serializers', 'app/serializers'

  minimum_coverage 80
  minimum_coverage_by_file 70
end
```

### Overcommit設定（Git Hooks for Ruby）

```yaml
# .overcommit.yml
PreCommit:
  RuboCop:
    enabled: true
    on_warn: fail
    command: ['bundle', 'exec', 'rubocop']

  Brakeman:
    enabled: true
    command: ['bundle', 'exec', 'brakeman', '--quiet', '--no-pager']

  BundlerAudit:
    enabled: true
    command: ['bundle', 'exec', 'bundle-audit', 'check', '--update']

PrePush:
  RSpec:
    enabled: true
    command: ['bundle', 'exec', 'rspec']
```

### ESLint設定（TypeScript/JavaScript）

```json
{
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended"
  ],
  "rules": {
    "@typescript-eslint/no-explicit-any": "error",
    "@typescript-eslint/explicit-function-return-type": "warn",
    "no-console": "warn",
    "max-lines-per-function": ["warn", 50]
  }
}
```

### Prettier設定

```json
{
  "semi": true,
  "singleQuote": true,
  "trailingComma": "es5",
  "printWidth": 100,
  "tabWidth": 2
}
```

### Husky (Git Hooks)

```json
{
  "husky": {
    "hooks": {
      "pre-commit": "lint-staged",
      "commit-msg": "commitlint -E HUSKY_GIT_PARAMS"
    }
  },
  "lint-staged": {
    "*.ts": ["eslint --fix", "prettier --write"],
    "*.md": ["prettier --write"]
  }
}
```

## チェックリスト

開発ガイドライン作成完了前に以下を確認:

- [ ] コーディング規約が具体的に定義されている
- [ ] Good/Badの例が含まれている
- [ ] Git ワークフローが明確である
- [ ] テスト戦略が定義されている
- [ ] セキュリティガイドラインが含まれている
- [ ] パフォーマンスのベストプラクティスが記載されている
- [ ] コードレビューの基準が明確である
- [ ] 自動化可能なルールにツール設定が含まれている
- [ ] トラブルシューティングガイドが含まれている
- [ ] チーム全員が理解できる内容である

## よくある間違い

### 1. 理想論に終始する

**悪い例:**
「常に完璧なコードを書く」

**良い例:**
「関数は50行以内、クラスは200行以内を目安とする」

### 2. 自動化できるものをドキュメント化だけで済ます

**悪い例:**
「コードはPrettierでフォーマットすること」（設定なし）

**良い例:**
「コードはPrettierでフォーマットすること」+ Prettier設定ファイル + pre-commit hook

### 3. 曖昧な表現

**悪い例:**
「適切にエラーハンドリングを行う」

**良い例:**
「すべての非同期処理はtry-catchでラップし、エラーは統一されたフォーマットでログ出力する」
