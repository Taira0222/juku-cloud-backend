# Juku Cloud – Backend (Ruby on Rails 8, API mode)

本リポジトリは Juku Cloud のバックエンドAPIです。  
ECS Fargate 上で稼働し、RDS(PostgreSQL) と接続します。

- フロントエンド: https://github.com/Taira0222/juku-cloud-frontend

## ✨ 技術スタック
- Ruby 3.4.4 / Rails 8.0.3 (API mode)
- PostgreSQL 15
- devise_token_auth / Alba / Kaminari
- RSpec / SimpleCov
- RuboCop / Bullet / Bundler Audit

## 🧱 ディレクトリ構成（抜粋）
```
app/
├─ controllers/ # v1配下にAPIエンドポイント、concernsに共通処理（認証/エラー）
├─ models/ # ドメインモデル（subjects/availability/teaching 等で責務分割）
├─ queries/ # 一覧・検索のQueryオブジェクト
├─ serializers/ # Albaシリアライザでレスポンス統一
└─ services/ # ユースケース（作成/更新/検証/関連更新・upsert/delete最適化）
config/
├─ environments/
└─ initializers/ # devise/cors/bullet など
db/
└─ migrate/
ecs/
└─ taskdef.json # CIでレンダリングするECSタスク定義
spec/
├─ requests/ # 統合テスト
├─ models/
└─ services/
```

## 🔐 認証

- `devise_token_auth` を採用（access-token/client/uid でステートレス運用）
- CSRF面でCookie前提より攻撃面を縮小。CORS/HTTPS必須

## 📄 API 概要（例）
```
POST   /api/v1/auth          # 講師招待→登録
POST   /api/v1/auth/sign_in  # ログイン
DELETE /api/v1/auth/sign_out # ログアウト

GET    /api/v1/students
POST   /api/v1/students
PATCH  /api/v1/students/:id
DELETE /api/v1/students/:id

GET    /api/v1/lesson_notes?student_id=...&subject_id=...
POST   /api/v1/lesson_notes
PATCH  /api/v1/lesson_notes/:id
DELETE /api/v1/lesson_notes/:id
```

## 🧪 テスト & カバレッジ
```
bundle exec rspec
```

- 実績: Line 98% / Branch 89%（目標 80%+）
- BulletでN+1クエリ検出、Query/Service層で最適化（upsert_all / delete_all など）

## 📦 招待トークン（実装方針）

- HMAC-SHA256 採用：改ざん防止＆検索可能で高速
- bcrypt等は非決定的のため検索不可、MessageVerifierはトークンが長くUX低下 → 不採用

## 🧰 運用（CI/CD）

- GitHub Actions → ECRへビルド/プッシュ → ECSへデプロイ
- 反映後に rails db:migrate を自動実行
- 監視/ログは CloudWatch

## ☁️ インフラ要点

- ECS Fargate（Single-AZ運用・将来拡張可能）
- RDS PostgreSQL（Single-AZ → 将来Multi-AZに変更可能）
- S3 + CloudFront（フロント配信、CSPでXSS軽減）
- OIDCでGitHub ActionsからAWSへ安全に権限委譲（長期キー不要）