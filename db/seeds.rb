require "yaml"
require "erb"

SEED_DIR = Rails.root.join("db", "seed_data")

def yaml_safe_load(file_name)
  path = SEED_DIR.join(file_name)
  YAML.safe_load(File.read(path))
end

def load_trait_sets(file_name)
  raw = yaml_safe_load(file_name)
  #  [{title=>'...', ...}] → [{title: :title, ...}] に整形
  raw.map { |set| set.map { |h| h.deep_symbolize_keys } }
end

def load_notes_by_subject(file_name)
  raw = yaml_safe_load(file_name)

  # {"1"=>[{...}, ...]} → {1=> [{...}, ...]} に整形
  raw
    .transform_keys { |k| k.to_i }
    .transform_values { |arr| Array(arr).map { |h| h.deep_symbolize_keys } }
end

TRAIT_SETS = load_trait_sets("student_traits.yml")
NOTES_BY_SUBJECT = load_notes_by_subject("lesson_notes.yml")

# 教科が9科目
CLASS_SUBJECTS_COUNT = 5
# 教科を作成
CLASS_SUBJECTS_COUNT.times { |i| ClassSubject.create!(name: i) }

# 曜日が7つ
AVAILABLE_DAYS_COUNT = 7
# 曜日を作成
AVAILABLE_DAYS_COUNT.times { |i| AvailableDay.create!(name: i) }

# 1人の管理者が担当する先生の数
TEACHERS_COUNT = 10

# 1人目の管理者が担当する先生の初めの番号
FIRST_TEACHER_START_NUMBER = 1
# 2人目の管理者が担当する先生の初めの番号
SECOND_TEACHER_START_NUMBER = FIRST_TEACHER_START_NUMBER + TEACHERS_COUNT

# 生徒1人あたりの受講科目数（例：1〜3科目）
STUDENT_SUBJECTS_MIN = 1
STUDENT_SUBJECTS_MAX = 3

# 生徒1人あたりの受講曜日数（例：1〜3曜日）
STUDENT_DAYS_MIN = 1
STUDENT_DAYS_MAX = 3

# 科目(5教科)と曜日を取得して配列化
SUBJECTS = ClassSubject.order(:id).to_a
DAYS = AvailableDay.order(:id).to_a
# ユーザーを作成するメソッド
def create_user(email, name, role, employment_status, school)
  User.create!(email: email) do |user|
    user.name = name
    user.password = "password"
    user.password_confirmation = "password"
    user.confirmed_at = Time.current
    user.confirmation_sent_at = Time.current
    user.role = role
    user.employment_status = employment_status
    user.school = school
  end
end

# 学校を作成するメソッド
def create_school(school_code, school_name, owner)
  School.create!(school_code: school_code) do |school|
    school.name = school_name
    school.owner = owner
  end
end

# 先生を作成するメソッド
def create_teacher(count, teachers, start_number, school)
  count.times do |i|
    employment_status =
      case i % 3
      when 0
        :active
      when 1
        :inactive
      when 2
        :on_leave
      end

    teacher =
      create_user(
        "teacher#{i + start_number}@example.com",
        "Teacher #{i + start_number}",
        :teacher,
        employment_status,
        school
      )

    # 教師の担当可能教科/曜日は「作成時に一度だけ」割り当てる
    teacher.teachable_subjects = pick_some(SUBJECTS, min: 1, max: 5)
    teacher.workable_days = pick_some(DAYS, min: 1, max: 4)
    teacher.save!

    teachers << teacher
  end
end

STUDENT_STATUSES = %i[active graduated quit paused] # 0: active, 1: graduated, 2: quit, 3: paused
SCHOOL_STAGES = %i[elementary_school junior_high_school high_school] # 0: elementary_school, 1: junior_high_school, 2: high_school
GRADES = [ 1, 2, 3 ] # 1 ~ 3 年生

# 生徒を作成するメソッド
def create_students_for_teacher(teachers, school_code, num_students = 2)
  school = School.find_by!(school_code: school_code)

  teachers.each do |teacher|
    # 教師の担当可能セット（オブジェクト配列/ID配列）
    teacher_subjects = teacher.teachable_subjects.to_a
    teacher_days = teacher.workable_days.to_a
    teacher_subject_ids = teacher_subjects.map(&:id)
    teacher_day_ids = teacher_days.map(&:id)

    num_students.times do |i|
      status = STUDENT_STATUSES[i % STUDENT_STATUSES.size]
      school_stage = SCHOOL_STAGES[i % SCHOOL_STAGES.size]
      grade = GRADES[i % GRADES.size]

      student =
        Student.create! do |s|
          s.name = Faker::Name.name
          s.school = school
          s.status = status
          s.joined_on = Time.current
          s.school_stage = school_stage
          s.grade = grade
          s.desired_school = Faker::University.name
        end

      # 生徒の科目・曜日は「教師が可能な集合」のサブセットから選ぶ（必ず交差する）
      student_subjects =
        pick_some(
          teacher_subjects,
          min: STUDENT_SUBJECTS_MIN,
          max: STUDENT_SUBJECTS_MAX
        )
      student_days =
        pick_some(teacher_days, min: STUDENT_DAYS_MIN, max: STUDENT_DAYS_MAX)

      student.class_subjects = student_subjects
      student.available_days = student_days
      student.save!

      student.student_class_subjects.each do |scs|
        day = student.available_days.sample
        Teaching::Assignment.create!(
          user: teacher,
          student_class_subject: scs,
          available_day: day
        )
      end
    end
  end
end

def pick_some(arr, min:, max:)
  count = rand(min..[ max, arr.size ].min)
  arr.sample(count)
end

def create_student_traits_and_lesson_notes(school, admin)
  school.students.each_with_index do |student, i|
    # student_traitの作成
    TRAIT_SETS[i % TRAIT_SETS.size].each do |trait_attrs|
      student.student_traits.create!(
        title: trait_attrs[:title],
        category: trait_attrs[:category],
        description: trait_attrs[:description]
      )
    end

    # NOTES_BY_SUBJECTから、studentの受講科目に対応するものを抽出
    match_subjects =
      student.class_subjects.select { |subj| NOTES_BY_SUBJECT.key?(subj.id) }
    scs_ids =
      Subjects::StudentLink.where(
        student: student,
        class_subject: match_subjects
      ).pluck(:id, :class_subject_id)

    scs_ids.each do |scs_id, class_subject_id|
      notes = NOTES_BY_SUBJECT[class_subject_id]
      notes.each_with_index do |note_attrs, j|
        is_updated = (j % 3 == 0) # 3つに1つは更新履歴あり
        updated_by = is_updated ? admin : nil
        LessonNote.create!(
          student_class_subject_id: scs_id,
          title: note_attrs[:title],
          description: note_attrs[:description],
          note_type: note_attrs[:note_type],
          expire_date: Date.current + (rand(-5..30).days),
          created_by: admin,
          last_updated_by: updated_by
        )
      end
    end
  end
end

# 管理者1を作成
admin = create_user("admin@example.com", "Admin User", :admin, :active, nil)
# 1つ目の塾を作成
first_school = create_school("ABC123", "First School", admin)
# 先生たちを配列に貯める
first_teachers = []
# 先生を10人作成
create_teacher(
  TEACHERS_COUNT,
  first_teachers,
  FIRST_TEACHER_START_NUMBER,
  first_school
)
# 生徒を2人ずつ作成
create_students_for_teacher(first_teachers, "ABC123")

# 管理者2を作成
another_admin =
  create_user(
    "another_admin@example.com",
    "Another Admin User",
    :admin,
    :active,
    nil
  )
# 2つ目の塾を作成
second_school = create_school("DEF123", "Second School", another_admin)
second_teachers = []
# 先生を10人作成
create_teacher(
  TEACHERS_COUNT,
  second_teachers,
  SECOND_TEACHER_START_NUMBER,
  second_school
)
# 生徒を2人ずつ作成
create_students_for_teacher(second_teachers, "DEF123")

# 管理者と講師を対象にランダム割り当て
User
  .where(role: %i[admin])
  .each do |user|
    user.class_subjects = pick_some(SUBJECTS, min: 1, max: 5)
    user.available_days = pick_some(DAYS, min: 1, max: 4)
    user.save!
  end

create_student_traits_and_lesson_notes(first_school, admin)
create_student_traits_and_lesson_notes(second_school, another_admin)
