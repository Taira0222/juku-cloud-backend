# Juku Cloud – Back end (Ruby on Rails 8, API mode)

English | [日本語](README.ja.md)

The API for [Juku Cloud](https://github.com/Taira0222/juku-cloud), a SaaS for tutoring schools. The [front end](https://github.com/Taira0222/juku-cloud-frontend) is a React SPA.

> **Status:** no longer online. It ran on ECS Fargate with RDS PostgreSQL. CI (tests and static analysis) still runs on every push.

## Stack

- Ruby 3.4.13, Rails 8.1 (API mode)
- PostgreSQL 15
- devise_token_auth, Alba, Kaminari
- RSpec, SimpleCov
- RuboCop, Bullet, Brakeman, bundler-audit

## Structure (excerpt)

```
app/
├─ controllers/  # API endpoints under v1; shared auth and error handling in concerns
├─ models/       # Domain models (split into subjects, availability, teaching, ...)
├─ queries/      # Query objects for lists and search
├─ serializers/  # Alba serializers for consistent responses
└─ services/     # Use cases (create, update, validate, update relations with upsert / delete)
config/
├─ environments/
└─ initializers/ # devise, CORS, Bullet, ...
db/
└─ migrate/
ecs/
└─ taskdef.json  # ECS task definition, rendered in CI
spec/
├─ requests/     # Integration tests
├─ models/
└─ services/
```

## Authentication

- `devise_token_auth` with `access-token` / `client` / `uid` headers. The API keeps no sessions, and tokens rotate on each response.
- No cookies, so there is less CSRF exposure. CORS and HTTPS are required.

## API (examples)

```
POST   /api/v1/auth          # Teacher sign-up from an invite
POST   /api/v1/auth/sign_in  # Sign in
DELETE /api/v1/auth/sign_out # Sign out

GET    /api/v1/students
POST   /api/v1/students
PATCH  /api/v1/students/:id
DELETE /api/v1/students/:id

GET    /api/v1/lesson_notes?student_id=...&subject_id=...
POST   /api/v1/lesson_notes
PATCH  /api/v1/lesson_notes/:id
DELETE /api/v1/lesson_notes/:id
```

## Invite tokens

- HMAC-SHA256: tamper-proof, and the token can be looked up directly.
- bcrypt was ruled out because its hashes can't be looked up, and MessageVerifier because its tokens are long.

## Tests

```bash
bundle exec rspec
```

- Coverage: lines 97% · branches 90% (target: 80%+)
- Bullet catches N+1 queries; query and service objects use `upsert_all` and `delete_all`.

## Deploy (switched off)

- GitHub Actions → build and push to ECR → deploy to ECS → run `rails db:migrate`
- AWS access through OIDC, with no long-lived keys. Logs in CloudWatch.
- ECS Fargate and RDS PostgreSQL both ran in a single AZ; RDS can move to Multi-AZ.

## Run locally

Open the repository in the Dev Container (`.devcontainer/`). It starts Rails and PostgreSQL 15. First create `.devcontainer/.env` (these match the defaults in `config/database.yml`):

```bash
POSTGRES_USER=postgres
POSTGRES_PASSWORD=password
POSTGRES_DB=juku_cloud_backend_development
```

Then, inside the container:

```bash
bin/setup   # Installs gems, prepares the database, and starts the server on port 3000
```
