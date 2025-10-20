# Juku Cloud – Frontend (React + Vite + TypeScript)

本リポジトリは Juku Cloud のフロントエンド（SPA）です。  
S3 + CloudFrontでホスティングし、Rails API と通信します。

- 本番サービス: https://www.juku-cloud.com
- バックエンド: https://github.com/Taira0222/juku-cloud-backend

## ✨ 技術スタック
- React 19 / Vite 7 / TypeScript 5
- Tailwind CSS / shadcn/ui
- Zustand / TanStack Query
- Axios / Zod
- Vitest / Testing Library / MSW
- ESLint / Prettier

## 🧱 ディレクトリ構成（抜粋）
```
src/
├─ Router/ # 認可付きルート（AuthRoute/ProtectedRoute/RoleRoute）
├─ pages/ # 画面コンポーネント
├─ features/ # 機能単位（auth/students/studentTraits/lessonNotes/teachers...）
│ └─ lessonNotes/ # 代表例: api/components/hooks/mutations/queries/types/test
├─ components/ # 共通UI（shadcn/ui ラップ等）
├─ stores/ # Zustand ストア
├─ api/ # グローバルAPIクライアント
├─ queries/ # 汎用クエリ
├─ mutations/ # 汎用ミューテーション
├─ lib/ # axiosクライアント/エラーハンドラ等
└─ tests/ # MSW サーバ/fixtures
```

## 🧪 テスト & カバレッジ
```bash
npm run test       # ユニット/結合（MSWでAPIモック）
npm run test:coverage

```
- 実績: stmts 97% / branch 92% / funcs 92% / lines 97%（目標: 80%以上）

## 🧩 実装のこだわり（要点）

- Zod: 期限日などフロント側でも厳密にバリデーション（UX向上＋バックエンドと二重防御）
- TanStack Query: サーバ状態のキャッシュ/同期/無効化を一元化（ZustandはUI状態中心）
- エラー処理の共通化: getErrorMessage() でAxios/422/通信障害を統一メッセージ化
- UI/UX: ステップが多いフォームは「選択に応じて表示を絞る」「バッジ切り替え」で直感操作

## 🔐 セキュリティ

- CSPはCloudFrontで付与（例：default-src 'self', script-src 'self' など）
- LocalStorageはXSSに弱いためCSPで外部スクリプト実行を抑制