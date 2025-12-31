# リポジトリ構造設計ガイドライン

## リポジトリ構造の目的

適切なリポジトリ構造は、コードの可読性、保守性、スケーラビリティを向上させます。チーム全体が一貫した構造を理解し、新しいファイルをどこに配置すべきか迷わないようにすることが重要です。

## 設計原則

### 1. レイヤードアーキテクチャに基づく構造

各レイヤーは明確な責務を持ち、依存関係は一方向にします。

```
API層 → アプリケーション層 → ドメイン層
  ↓           ↓                ↓
       インフラストラクチャ層
```

**依存関係のルール:**
- 外側のレイヤーは内側のレイヤーに依存できる
- 内側のレイヤーは外側のレイヤーに依存してはいけない
- ドメイン層は他のどのレイヤーにも依存しない

### 2. 関心の分離

各ディレクトリは単一の関心事に焦点を当てます。

**良い例:**
```
src/
├── domain/entities/User.ts        # ユーザーエンティティ
├── application/services/UserService.ts  # ユーザービジネスロジック
└── api/controllers/UserController.ts    # ユーザーAPI
```

**悪い例:**
```
src/
└── user/
    ├── User.ts
    ├── UserService.ts
    └── UserController.ts  # 異なるレイヤーが混在
```

### 3. スケーラビリティ

プロジェクトが成長しても構造が破綻しない設計にします。

## ディレクトリ構造のベストプラクティス

### API層 (src/api/)

**責務:** HTTPリクエスト/レスポンスの処理

```
api/
├── controllers/           # コントローラー（リクエストハンドラー）
│   ├── UserController.ts
│   └── AuthController.ts
├── middlewares/          # ミドルウェア
│   ├── auth.ts          # 認証ミドルウェア
│   ├── errorHandler.ts  # エラーハンドリング
│   └── logger.ts        # ロギング
├── routes/              # ルート定義
│   ├── userRoutes.ts
│   └── authRoutes.ts
└── validators/          # リクエストバリデーション
    ├── userValidator.ts
    └── authValidator.ts
```

**ポイント:**
- コントローラーはビジネスロジックを含まない
- バリデーションは専用のディレクトリに分離
- ルート定義は機能ごとに分割

### アプリケーション層 (src/application/)

**責務:** ビジネスロジックの実装、ユースケースの調整

```
application/
├── services/            # ビジネスロジック
│   ├── UserService.ts
│   └── AuthService.ts
├── usecases/           # ユースケース（複雑な場合のみ）
│   └── RegisterUserUseCase.ts
└── dto/                # データ転送オブジェクト
    ├── CreateUserDto.ts
    └── UpdateUserDto.ts
```

**ポイント:**
- サービスは単一責任の原則に従う
- ユースケースは複雑なビジネスフローの場合のみ使用
- DTOでレイヤー間のデータ変換を行う

### ドメイン層 (src/domain/)

**責務:** ビジネスドメインの中核的なロジックとルール

```
domain/
├── entities/           # エンティティ
│   └── User.ts
├── repositories/       # リポジトリインターフェース
│   └── IUserRepository.ts
└── value-objects/      # 値オブジェクト
    ├── Email.ts
    └── Password.ts
```

**ポイント:**
- エンティティはビジネスルールを含む
- リポジトリはインターフェースのみ（実装はインフラ層）
- 値オブジェクトは不変にする

### インフラストラクチャ層 (src/infrastructure/)

**責務:** 外部システムとのやり取り

```
infrastructure/
├── database/           # データベース設定
│   ├── connection.ts
│   └── migrations/
├── repositories/       # リポジトリ実装
│   └── UserRepository.ts
├── external/          # 外部API連携
│   └── EmailService.ts
└── cache/             # キャッシュ実装
    └── RedisCache.ts
```

**ポイント:**
- データベース、外部API等の実装詳細を隠蔽
- リポジトリインターフェースを実装
- 環境依存の設定を分離

### 共通モジュール (src/shared/)

**責務:** 複数のレイヤーで使用される共通機能

```
shared/
├── utils/             # ユーティリティ関数
│   ├── logger.ts
│   └── dateFormatter.ts
├── constants/         # 定数
│   ├── errorCodes.ts
│   └── config.ts
├── types/            # 共通型定義
│   └── common.ts
└── errors/           # カスタムエラークラス
    ├── ValidationError.ts
    └── NotFoundError.ts
```

**ポイント:**
- ビジネスロジックを含まない純粋な関数のみ
- どのレイヤーからも依存可能
- 循環依存を避ける

## 命名規則の詳細

### ファイル名

**コンポーネント/クラス:**
```
UserController.ts      ✓ (PascalCase)
userController.ts      ✗
user-controller.ts     ✗
```

**ユーティリティ/関数:**
```
dateFormatter.ts       ✓ (camelCase)
DateFormatter.ts       ✗
date-formatter.ts      ✗
```

**テスト:**
```
UserService.test.ts    ✓
UserService.spec.ts    ✓
test-UserService.ts    ✗
```

### コード内の命名

**変数:**
```typescript
// Good
const userName = 'John';
const isActive = true;
const userList = [];

// Bad
const UserName = 'John';
const active = true;  // 真偽値には is/has を付ける
const user = [];      // 配列は複数形にする
```

**定数:**
```typescript
// Good
const MAX_RETRY_COUNT = 3;
const API_BASE_URL = 'https://api.example.com';

// Bad
const maxRetryCount = 3;
const apiBaseUrl = 'https://api.example.com';
```

**クラス/インターフェース:**
```typescript
// Good
class UserService {}
interface User {}
type UserRole = 'admin' | 'user';

// Bad
class userService {}
interface IUser {}  // I プレフィックスは不要
type user_role = 'admin' | 'user';
```

## インポートの整理

### 推奨される順序

```typescript
// 1. Node.js組み込みモジュール
import { promises as fs } from 'fs';
import path from 'path';

// 2. 外部ライブラリ
import express from 'express';
import { Request, Response } from 'express';

// 3. 内部モジュール（絶対パス）
import { UserService } from '@/application/services/UserService';
import { logger } from '@/shared/utils/logger';

// 4. 相対パス
import { validateUser } from './validators';
import { formatResponse } from './utils';

// 5. 型定義のみ
import type { User } from '@/domain/entities/User';
import type { CreateUserDto } from '@/application/dto/CreateUserDto';
```

### パスエイリアスの活用

```typescript
// Bad - 相対パスが長い
import { UserService } from '../../../application/services/UserService';

// Good - パスエイリアスを使用
import { UserService } from '@/application/services/UserService';
```

## テストファイルの配置

### オプション1: ソースコードと同じ階層

```
src/
├── application/
│   └── services/
│       ├── UserService.ts
│       └── UserService.test.ts
```

**メリット:**
- テストとソースが近い
- インポートパスが短い

**デメリット:**
- ビルド時に除外設定が必要

### オプション2: 専用のtestsディレクトリ（推奨）

```
src/
└── application/
    └── services/
        └── UserService.ts

tests/
└── unit/
    └── application/
        └── services/
            └── UserService.test.ts
```

**メリット:**
- テストファイルがビルドに含まれない
- テストの種類（unit/integration/e2e）で分類可能

**デメリット:**
- インポートパスが長くなる

## 環境設定の管理

### 環境ごとのファイル分離

```
.env.example          # テンプレート（機密情報なし）
.env.development      # 開発環境
.env.test             # テスト環境
.env.staging          # ステージング環境
.env.production       # 本番環境
```

### .env.exampleの内容

```bash
# データベース設定
DATABASE_URL=postgresql://user:password@localhost:5432/dbname

# API設定
API_PORT=3000
API_HOST=localhost

# JWT設定
JWT_SECRET=your-secret-key
JWT_EXPIRATION=24h

# 外部サービス
SMTP_HOST=smtp.example.com
SMTP_PORT=587
```

## Git管理のベストプラクティス

### .gitignore の例

```
# 依存関係
node_modules/
package-lock.json  # npm の場合。pnpm なら pnpm-lock.yaml を残す

# 環境変数
.env
.env.local
.env.*.local

# ビルド成果物
dist/
build/
*.js.map

# ログ
logs/
*.log

# IDE設定
.vscode/
.idea/
*.swp
*.swo

# OS固有
.DS_Store
Thumbs.db

# テストカバレッジ
coverage/
.nyc_output/
```

## チェックリスト

リポジトリ構造設計完了前に以下を確認:

- [ ] レイヤーごとにディレクトリが分離されている
- [ ] 各ディレクトリの責務が明確である
- [ ] 命名規則が一貫している
- [ ] パスエイリアスが設定されている
- [ ] .gitignoreが適切に設定されている
- [ ] .env.exampleが用意されている
- [ ] テストファイルの配置ルールが決まっている
- [ ] インポート順序のルールが決まっている
- [ ] スケーラビリティが考慮されている

## よくある間違い

### 1. 機能ごとのディレクトリ分割

**悪い例:**
```
src/
├── user/
│   ├── User.ts
│   ├── UserService.ts
│   ├── UserController.ts
│   └── UserRepository.ts
└── auth/
    ├── Auth.ts
    └── AuthService.ts
```

**問題点:** レイヤーが混在し、依存関係が複雑になる

**良い例:**
```
src/
├── domain/
│   ├── entities/User.ts
│   └── entities/Auth.ts
├── application/
│   ├── services/UserService.ts
│   └── services/AuthService.ts
├── api/
│   └── controllers/UserController.ts
└── infrastructure/
    └── repositories/UserRepository.ts
```

### 2. utilsディレクトリの肥大化

関連する機能ごとにディレクトリを分ける:

```typescript
// Bad
shared/utils/
├── utils.ts  // すべてのユーティリティが1ファイルに

// Good
shared/utils/
├── date/
│   ├── formatDate.ts
│   └── parseDate.ts
├── string/
│   ├── capitalize.ts
│   └── slugify.ts
└── validation/
    ├── isEmail.ts
    └── isPhone.ts
```

### 3. テストファイルの命名不統一

チーム全体で統一する:

```
// Option 1: .test.ts
UserService.test.ts

// Option 2: .spec.ts
UserService.spec.ts

// 混在させない
UserService.test.ts
AuthService.spec.ts  ✗
```
