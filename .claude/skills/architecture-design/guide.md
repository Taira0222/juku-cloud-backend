# アーキテクチャ設計ガイド - 実装時のコード例集

このガイドは、アーキテクチャ設計書（`docs/architecture.md`）に基づいて**実装する際**の具体的なコード例を提供します。

**ファイルの関係:**
1. [SKILL.md](./SKILL.md) でスキル全体の流れを理解
2. [template.md](./template.md) を使って `docs/architecture.md` を作成
3. **このguide.md** を見ながら実際にコードを実装

**使い方:**
- 各レイヤーの「✅ 良い例」を参考に実装する
- 「❌ 悪い例」を避ける
- パッと見て分かるように、最小限のコードで本質を示す

---

## 目次

1. [Controller Layer](#1-controller-layer)
2. [Service Layer](#2-service-layer)
3. [Query Layer](#3-query-layer)
4. [Model Layer](#4-model-layer)
5. [Serializer Layer](#5-serializer-layer)
6. [Job Layer](#6-job-layer)
7. [エラーハンドリング](#エラーハンドリング)
8. [テストの書き方](#テストの書き方)
   - [Controller Spec](#controller-spec)
   - [Service Spec](#service-spec)
   - [Query Spec](#query-spec)
   - [Model Spec](#model-spec)
   - [Serializer Spec](#serializer-spec)
   - [Job Spec](#job-spec)
9. [セキュリティ](#セキュリティ)
10. [まとめ](#まとめ)

---

## 1. Controller Layer

### 責務
- リクエスト受付、認証、Service呼び出し、レスポンス返却のみ
- **ビジネスロジックを書かない**

### ✅ 良い例

```ruby
class Api::V1::LessonsController < Api::V1::BaseController
  before_action :authenticate_api_v1_user!

  def create
    result = LessonService.create(
      user: current_api_v1_user,
      params: lesson_params
    )

    if result.success?
      render json: LessonSerializer.new(result.lesson).serialize, status: :created
    else
      render json: { errors: result.errors }, status: :unprocessable_entity
    end
  end

  private

  def lesson_params
    params.require(:lesson).permit(:title, :date, :student_id)
  end
end
```

**ポイント:**
- ビジネスロジックは`LessonService`に委譲
- Strong Parametersで入力検証
- Serializerでレスポンス整形
- 適切なHTTPステータスコード

### ❌ 悪い例

```ruby
class Api::V1::LessonsController < Api::V1::BaseController
  def create
    # ❌ Controllerにビジネスロジックを書いている
    lesson = Lesson.new(lesson_params)
    lesson.teacher = current_api_v1_user

    # ❌ 複数の操作を直接書いている
    if lesson.save
      GradeRecord.create!(lesson: lesson)
      LessonNotificationJob.perform_later(lesson.id)
      StudentStatistics.update_for_lesson(lesson)

      render json: lesson, status: :created
    else
      # ❌ エラーレスポンスの形式が不統一
      render json: lesson.errors, status: :unprocessable_entity
    end
  end
end
```

**問題点:**
- Controllerにビジネスロジックが散在
- トランザクション管理がない
- テストが書きにくい
- 再利用できない

---

## 2. Service Layer

### 責務
- ビジネスロジックの実装
- トランザクション管理
- 複数モデルの操作

### ✅ 良い例

```ruby
class LessonService
  class Result
    attr_reader :lesson, :errors

    def initialize(lesson: nil, errors: [])
      @lesson = lesson
      @errors = errors
    end

    def success?
      errors.empty?
    end
  end

  def self.create(user:, params:)
    lesson = user.lessons.build(params)

    ActiveRecord::Base.transaction do
      if lesson.save
        GradeRecord.create!(lesson: lesson)
        LessonNotificationJob.perform_later(lesson.id)
        Result.new(lesson: lesson)
      else
        Result.new(errors: lesson.errors.full_messages)
      end
    end
  rescue StandardError => e
    Rails.logger.error("Lesson creation failed: #{e.message}")
    Result.new(errors: ['レッスンの作成に失敗しました'])
  end
end
```

**ポイント:**
- Resultパターンで成功/失敗を表現
- トランザクションで整合性を保証
- エラーハンドリングとロギング

### ❌ 悪い例

```ruby
class LessonService
  def self.create(user:, params:)
    lesson = user.lessons.create!(params)
    # ❌ トランザクションがない
    GradeRecord.create!(lesson: lesson)
    # ❌ エラーハンドリングがない
    LessonNotificationJob.perform_later(lesson.id)
    # ❌ 戻り値が統一されていない（booleanとモデルが混在）
    lesson
  rescue ActiveRecord::RecordInvalid
    # ❌ エラー情報が失われる
    false
  end
end
```

**問題点:**
- トランザクションがなく、途中で失敗すると不整合
- エラーハンドリングが不十分
- 戻り値が統一されていない
- 呼び出し側でエラー原因が分からない

---

## 3. Query Layer

### 責務
- 複雑なデータ取得ロジック
- N+1問題の回避

### ✅ 良い例

```ruby
class LessonQuery
  def self.for_user(user)
    case user.role
    when 'teacher'
      Lesson.where(teacher: user)
            .includes(:student, :grade_record)
            .order(date: :desc)
    when 'student'
      Lesson.where(student: user)
            .includes(:teacher)
            .order(date: :desc)
    else
      Lesson.none
    end
  end

  def self.search(params)
    lessons = Lesson.includes(:student, :teacher)

    lessons = lessons.where(student_id: params[:student_id]) if params[:student_id].present?
    lessons = lessons.where(status: params[:status]) if params[:status].present?
    lessons = lessons.where('date >= ?', params[:date_from]) if params[:date_from].present?

    lessons
  end
end
```

**ポイント:**
- `includes`でN+1問題を回避
- 動的な検索条件の組み立て
- 再利用可能なクエリ

### ❌ 悪い例

```ruby
# ❌ Controllerに直接書いている
class Api::V1::LessonsController < Api::V1::BaseController
  def index
    # ❌ N+1問題が発生
    @lessons = Lesson.where(teacher: current_api_v1_user)
    # ビューで @lesson.student.name を呼ぶと N+1
  end
end

# ❌ 複雑なクエリをModelに書いている
class Lesson < ApplicationRecord
  def self.search(params)
    # Modelは単純なスコープのみにすべき
    # 複雑な検索ロジックはQueryオブジェクトへ
  end
end
```

**問題点:**
- N+1問題が発生
- 再利用できない
- テストが書きにくい

---

## 4. Model Layer

### 責務
- データ永続化、バリデーション、アソシエーション
- **複雑なビジネスロジックを書かない**

### ✅ 良い例

```ruby
class Lesson < ApplicationRecord
  belongs_to :teacher, class_name: 'User'
  belongs_to :student, class_name: 'User'
  has_one :grade_record, dependent: :destroy

  validates :title, presence: true, length: { maximum: 100 }
  validates :date, presence: true
  validates :status, inclusion: { in: %w[scheduled completed cancelled] }

  validate :teacher_must_be_teacher_role

  scope :upcoming, -> { where('date >= ?', Date.current).order(:date) }

  # シンプルなビジネスロジックのみ
  def can_be_edited_by?(user)
    teacher == user || user.admin?
  end

  private

  def teacher_must_be_teacher_role
    errors.add(:teacher, 'must have teacher role') unless teacher&.teacher?
  end
end
```

**ポイント:**
- バリデーションでデータ整合性を保証
- スコープで再利用可能なクエリ
- シンプルなビジネスロジックのみ

### ❌ 悪い例

```ruby
class Lesson < ApplicationRecord
  belongs_to :teacher, class_name: 'User'
  belongs_to :student, class_name: 'User'

  # ❌ 複雑なビジネスロジックをModelに書いている
  def complete_lesson(score, feedback)
    transaction do
      update!(status: 'completed', completed_at: Time.current)
      GradeRecord.create!(lesson: self, score: score, feedback: feedback)
      StudentStatistics.update_for_lesson(self)
      LessonCompletionMailer.notify(self).deliver_later
    end
  end

  # ❌ コールバックで複雑な処理
  after_create :send_notifications, :update_statistics, :create_related_records
end
```

**問題点:**
- Modelにビジネスロジックが集中
- テストが書きにくい
- 再利用できない
- コールバック地獄

---

## 5. Serializer Layer

### 責務
- JSONレスポンスの整形
- **機密情報を含めない**

### ✅ 良い例

```ruby
class LessonSerializer
  include Alba::Resource

  attributes :id, :title, :date, :status

  attribute :formatted_date do |lesson|
    lesson.date.strftime('%Y年%m月%d日')
  end

  one :teacher, serializer: UserSerializer
  one :student, serializer: UserSerializer
  one :grade_record, if: proc { |lesson| lesson.completed? }
end

class UserSerializer
  include Alba::Resource

  # ✅ 必要な情報のみ
  attributes :id, :name, :email, :role
  # ✅ パスワード等の機密情報は含めない
end
```

**ポイント:**
- 必要な情報のみ公開
- 機密情報を含めない
- 条件付き表示で柔軟性を確保

### ❌ 悪い例

```ruby
class UserSerializer
  include Alba::Resource

  # ❌ 機密情報を含めている
  attributes :id, :name, :email, :encrypted_password, :reset_password_token

  # ❌ 不要な情報まで返している
  attributes :created_at, :updated_at, :sign_in_count, :current_sign_in_ip
end
```

**問題点:**
- セキュリティリスク
- 不要な情報を返している
- パフォーマンス低下

---

## 6. Job Layer

### 責務
- 非同期処理の実装
- 時間のかかる処理のバックグラウンド実行
- メール送信、通知、データ集計など

### ✅ 良い例

```ruby
class LessonNotificationJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: :exponentially_longer, attempts: 5

  def perform(lesson_id)
    lesson = Lesson.find(lesson_id)

    # 通知送信
    LessonNotificationMailer.notify(lesson).deliver_now

    # プッシュ通知
    send_push_notification(lesson)

    Rails.logger.info("Lesson notification sent: #{lesson.id}")
  end

  private

  def send_push_notification(lesson)
    # プッシュ通知の実装
    PushNotificationService.send(
      user: lesson.student,
      title: 'New Lesson Scheduled',
      body: "#{lesson.title} on #{lesson.date}"
    )
  end
end
```

**ポイント:**
- `retry_on`でリトライ戦略を定義
- ログ出力でジョブの実行を追跡
- プライベートメソッドで処理を分割

### ✅ 良い例 - スケジュールされたジョブ

```ruby
class DailyReportJob < ApplicationJob
  queue_as :low_priority

  def perform
    date = Date.current

    User.teachers.find_each do |teacher|
      report = generate_daily_report(teacher, date)
      DailyReportMailer.send_report(teacher, report).deliver_now
    end
  end

  private

  def generate_daily_report(teacher, date)
    {
      lessons_count: teacher.lessons.where(date: date).count,
      completed_count: teacher.lessons.where(date: date, status: 'completed').count,
      students: teacher.students.count
    }
  end
end
```

**ポイント:**
- `find_each`でメモリ効率を向上
- キューの優先度を設定（low_priority）
- データ集計ロジックをプライベートメソッドに分離

### ❌ 悪い例

```ruby
class LessonNotificationJob < ApplicationJob
  def perform(lesson_id)
    # ❌ エラーハンドリングがない
    lesson = Lesson.find(lesson_id)

    # ❌ 複数の外部APIを順次呼び出し（失敗時のリトライがない）
    send_email(lesson)
    send_sms(lesson)
    send_push(lesson)
    update_analytics(lesson)

    # ❌ ログがない
  end

  # ❌ リトライ戦略が定義されていない
  # ❌ キューが指定されていない
end

class HeavyDataProcessingJob < ApplicationJob
  def perform
    # ❌ find_eachを使わず、全レコードをメモリに読み込む
    User.all.each do |user|
      process_user_data(user)
    end
  end
end
```

**問題点:**
- エラーハンドリングとリトライ戦略がない
- ログがなく、ジョブの実行状況が追跡できない
- メモリ効率が悪い
- キューの優先度制御がない

---

## エラーハンドリング

### ✅ 良い例 - 統一されたエラーレスポンス

```ruby
class Api::V1::BaseController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActionController::ParameterMissing, with: :parameter_missing
  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid

  private

  def record_not_found(exception)
    render json: {
      error: {
        code: 'NOT_FOUND',
        message: exception.message
      }
    }, status: :not_found
  end

  def parameter_missing(exception)
    render json: {
      error: {
        code: 'PARAMETER_MISSING',
        message: exception.message,
        param: exception.param
      }
    }, status: :bad_request
  end

  def record_invalid(exception)
    render json: {
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Validation failed',
        details: exception.record.errors.full_messages
      }
    }, status: :unprocessable_entity
  end
end
```

**ポイント:**
- エラーレスポンスの形式を統一
- エラーコードで分類
- 詳細情報を含める

### ❌ 悪い例

```ruby
class Api::V1::LessonsController < ApplicationController
  def show
    lesson = Lesson.find(params[:id])
    render json: lesson
  rescue
    # ❌ エラーの種類が分からない
    # ❌ レスポンス形式が不統一
    render json: { error: 'Error' }, status: :bad_request
  end

  def create
    lesson = Lesson.create!(lesson_params)
    render json: lesson
  rescue ActiveRecord::RecordInvalid => e
    # ❌ レスポンス形式が統一されていない
    render json: e.record.errors, status: :unprocessable_entity
  end
end
```

**問題点:**
- エラーレスポンスの形式が不統一
- エラーの種類が分からない
- クライアントが処理しにくい

---

## テストの書き方

### Controller Spec

#### ✅ 良い例

```ruby
# spec/requests/api/v1/lessons_spec.rb
RSpec.describe 'Api::V1::Lessons', type: :request do
  let(:teacher) { create(:user, :teacher) }
  let(:auth_headers) { teacher.create_new_auth_token }

  describe 'POST /api/v1/lessons' do
    let(:student) { create(:user, :student) }
    let(:valid_params) do
      { lesson: { title: 'Math', date: Date.tomorrow, student_id: student.id } }
    end

    it 'creates a new lesson' do
      expect {
        post '/api/v1/lessons', params: valid_params, headers: auth_headers
      }.to change(Lesson, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['title']).to eq('Math')
    end

    it 'returns errors for invalid params' do
      post '/api/v1/lessons', params: { lesson: { title: '' } }, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['errors']).to be_present
    end

    it 'requires authentication' do
      post '/api/v1/lessons', params: valid_params

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
```

**ポイント:**
- 正常系と異常系をテスト
- 認証のテスト
- レスポンスの検証

### Service Spec

#### ✅ 良い例

```ruby
# spec/services/lesson_service_spec.rb
RSpec.describe LessonService do
  describe '.create' do
    let(:teacher) { create(:user, :teacher) }
    let(:student) { create(:user, :student) }
    let(:params) { { title: 'Math', date: Date.tomorrow, student_id: student.id } }

    it 'creates a lesson successfully' do
      result = described_class.create(user: teacher, params: params)

      expect(result).to be_success
      expect(result.lesson).to be_persisted
      expect(result.lesson.title).to eq('Math')
    end

    it 'creates a grade record' do
      expect {
        described_class.create(user: teacher, params: params)
      }.to change(GradeRecord, :count).by(1)
    end

    it 'enqueues a notification job' do
      expect {
        described_class.create(user: teacher, params: params)
      }.to have_enqueued_job(LessonNotificationJob)
    end

    it 'returns errors for invalid params' do
      result = described_class.create(user: teacher, params: { title: '' })

      expect(result).not_to be_success
      expect(result.errors).to include(/Title/)
    end

    it 'rolls back on error' do
      allow_any_instance_of(Lesson).to receive(:save).and_return(false)

      expect {
        described_class.create(user: teacher, params: params)
      }.not_to change(GradeRecord, :count)
    end
  end
end
```

**ポイント:**
- ビジネスロジックをテスト
- トランザクションのロールバックをテスト
- ジョブのエンキューをテスト

### Query Spec

#### ✅ 良い例

```ruby
# spec/queries/lesson_query_spec.rb
RSpec.describe LessonQuery do
  describe '.for_user' do
    let(:teacher) { create(:user, :teacher) }
    let(:student) { create(:user, :student) }
    let!(:teacher_lesson) { create(:lesson, teacher: teacher) }
    let!(:student_lesson) { create(:lesson, student: student) }

    context 'when user is a teacher' do
      it 'returns lessons taught by the teacher' do
        lessons = described_class.for_user(teacher)
        expect(lessons).to include(teacher_lesson)
        expect(lessons).not_to include(student_lesson)
      end

      it 'eager loads associations to avoid N+1' do
        expect {
          described_class.for_user(teacher).each do |lesson|
            lesson.student.name
            lesson.grade_record&.score
          end
        }.not_to exceed_query_limit(3)
      end
    end

    context 'when user is a student' do
      it 'returns lessons for the student' do
        lessons = described_class.for_user(student)
        expect(lessons).to include(student_lesson)
        expect(lessons).not_to include(teacher_lesson)
      end
    end
  end

  describe '.search' do
    let!(:lesson1) { create(:lesson, status: 'completed', date: 1.day.ago) }
    let!(:lesson2) { create(:lesson, status: 'scheduled', date: 1.day.from_now) }

    it 'filters by status' do
      lessons = described_class.search(status: 'completed')
      expect(lessons).to include(lesson1)
      expect(lessons).not_to include(lesson2)
    end

    it 'filters by date_from' do
      lessons = described_class.search(date_from: Date.current)
      expect(lessons).to include(lesson2)
      expect(lessons).not_to include(lesson1)
    end

    it 'returns all lessons when no params' do
      lessons = described_class.search({})
      expect(lessons).to include(lesson1, lesson2)
    end
  end
end
```

**ポイント:**
- N+1クエリのテスト（`exceed_query_limit`マッチャー）
- 複数の検索条件のテスト
- エッジケースのテスト

### Model Spec

#### ✅ 良い例

```ruby
# spec/models/lesson_spec.rb
RSpec.describe Lesson, type: :model do
  describe 'associations' do
    it { should belong_to(:teacher).class_name('User') }
    it { should belong_to(:student).class_name('User') }
    it { should have_one(:grade_record).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:date) }
    it { should validate_length_of(:title).is_at_most(100) }
    it { should validate_inclusion_of(:status).in_array(%w[scheduled completed cancelled]) }
  end

  describe '#can_be_edited_by?' do
    let(:lesson) { create(:lesson) }

    it 'allows teacher to edit' do
      expect(lesson.can_be_edited_by?(lesson.teacher)).to be true
    end

    it 'allows admin to edit' do
      admin = create(:user, :admin)
      expect(lesson.can_be_edited_by?(admin)).to be true
    end

    it 'does not allow other users to edit' do
      other_user = create(:user)
      expect(lesson.can_be_edited_by?(other_user)).to be false
    end
  end
end
```

**ポイント:**
- バリデーションのテスト
- アソシエーションのテスト
- ビジネスロジックのテスト

### Serializer Spec

#### ✅ 良い例

```ruby
# spec/serializers/lesson_serializer_spec.rb
RSpec.describe LessonSerializer do
  let(:teacher) { create(:user, :teacher, name: 'Teacher Name') }
  let(:student) { create(:user, :student, name: 'Student Name') }
  let(:lesson) { create(:lesson, title: 'Math', date: Date.new(2025, 1, 15), teacher: teacher, student: student, status: 'scheduled') }

  describe '#serialize' do
    subject { described_class.new(lesson).serialize }

    it 'includes basic attributes' do
      expect(subject[:id]).to eq(lesson.id)
      expect(subject[:title]).to eq('Math')
      expect(subject[:status]).to eq('scheduled')
    end

    it 'formats the date' do
      expect(subject[:formatted_date]).to eq('2025年01月15日')
    end

    it 'includes teacher information' do
      expect(subject[:teacher][:id]).to eq(teacher.id)
      expect(subject[:teacher][:name]).to eq('Teacher Name')
    end

    it 'includes student information' do
      expect(subject[:student][:id]).to eq(student.id)
      expect(subject[:student][:name]).to eq('Student Name')
    end

    it 'does not include sensitive information' do
      expect(subject[:teacher]).not_to have_key(:encrypted_password)
      expect(subject[:student]).not_to have_key(:reset_password_token)
    end

    context 'when lesson is completed' do
      let(:lesson) { create(:lesson, :completed) }
      let!(:grade_record) { create(:grade_record, lesson: lesson, score: 85) }

      it 'includes grade_record' do
        expect(subject[:grade_record]).to be_present
        expect(subject[:grade_record][:score]).to eq(85)
      end
    end

    context 'when lesson is not completed' do
      it 'does not include grade_record' do
        expect(subject).not_to have_key(:grade_record)
      end
    end
  end
end
```

**ポイント:**
- 出力される属性の検証
- 機密情報が含まれていないことの確認
- 条件付き表示のテスト
- フォーマットされた値のテスト

### Job Spec

#### ✅ 良い例

```ruby
# spec/jobs/lesson_notification_job_spec.rb
RSpec.describe LessonNotificationJob, type: :job do
  let(:lesson) { create(:lesson) }

  describe '#perform' do
    it 'sends notification email' do
      expect {
        described_class.perform_now(lesson.id)
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'sends push notification' do
      expect(PushNotificationService).to receive(:send).with(
        user: lesson.student,
        title: 'New Lesson Scheduled',
        body: "#{lesson.title} on #{lesson.date}"
      )

      described_class.perform_now(lesson.id)
    end

    it 'logs the notification' do
      expect(Rails.logger).to receive(:info).with("Lesson notification sent: #{lesson.id}")
      described_class.perform_now(lesson.id)
    end

    context 'when lesson is not found' do
      it 'raises error and retries' do
        expect {
          described_class.perform_now(999999)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    it 'is enqueued in the default queue' do
      described_class.perform_later(lesson.id)
      expect(described_class).to have_been_enqueued.on_queue('default')
    end

    it 'retries on error' do
      allow(Lesson).to receive(:find).and_raise(StandardError)

      expect {
        described_class.perform_now(lesson.id)
      }.to raise_error(StandardError)

      # リトライ設定の確認
      expect(described_class.retry_on_block_for(StandardError)).to be_present
    end
  end
end
```

**ポイント:**
- メール送信のテスト
- 外部サービス呼び出しのモック
- ログ出力の検証
- キューの設定確認
- リトライ動作のテスト

### ❌ 悪い例

```ruby
# ❌ テストが不十分
RSpec.describe LessonService do
  it 'works' do
    result = LessonService.create(user: user, params: params)
    expect(result).to be_success
  end
end

# ❌ 異常系のテストがない
# ❌ トランザクションのテストがない
# ❌ 関連データのテストがない
```

---

## セキュリティ

### ✅ 良い例

```ruby
class Api::V1::LessonsController < Api::V1::BaseController
  before_action :authenticate_api_v1_user!
  before_action :set_lesson, only: [:show, :update, :destroy]
  before_action :authorize_lesson!, only: [:update, :destroy]

  private

  def set_lesson
    # ✅ ユーザーのスコープ内で検索
    @lesson = current_api_v1_user.lessons.find(params[:id])
  end

  def authorize_lesson!
    # ✅ 権限チェック
    unless @lesson.can_be_edited_by?(current_api_v1_user)
      render json: { error: { code: 'FORBIDDEN' } }, status: :forbidden
    end
  end

  def lesson_params
    # ✅ Strong Parameters
    params.require(:lesson).permit(:title, :date, :student_id)
  end
end
```

### ❌ 悪い例

```ruby
class Api::V1::LessonsController < ApplicationController
  def update
    # ❌ 認証チェックがない
    # ❌ 権限チェックがない
    lesson = Lesson.find(params[:id])

    # ❌ Strong Parametersを使っていない
    lesson.update!(params[:lesson])

    render json: lesson
  end
end
```

---

## まとめ

### 設計の原則

1. **レイヤーの責務を守る**
   - Controller: リクエスト処理のみ
   - Service: ビジネスロジック
   - Model: データ永続化のみ

2. **エラーハンドリング**
   - 統一されたエラーレスポンス
   - 適切なHTTPステータスコード
   - ロギング

3. **テスト**
   - 正常系と異常系
   - トランザクションのテスト
   - 認証・認可のテスト

4. **セキュリティ**
   - 認証・認可
   - Strong Parameters
   - スコープによる権限制御

このガイドの例を参考に、保守性の高いコードを書いてください。
