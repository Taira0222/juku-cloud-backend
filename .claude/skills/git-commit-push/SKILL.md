---
name: git-commit-push
description: 変更内容を分析してコミットメッセージを自動生成し、add → commit → push を実行するスキル
---

# Git Commit & Push Skill

## 手順

1. **ステージングする**

   ```bash
   git add -A
   ```

2. **差分を確認する**

   ```bash
   git diff --staged  # ステージングと前回コミットの差分
   git status
   ```

3. **コミットメッセージを生成してユーザーに提示する**

   `git diff --staged` の差分から「何が変わったか」を要約し、直前のコミットメッセージの文体に合わせる。

4. **ユーザーの承認を得る**

5. **commit → push を実行する**

   ```bash
   git commit -m "<メッセージ>"
   git push origin <current-branch>
   ```

## 注意

- `git add -A` の前に `git status` で意図しないファイルが含まれていないか確認する
- `main` / `master` への直接プッシュはユーザーに確認する
- `--force` / `--no-verify` は使用しない
