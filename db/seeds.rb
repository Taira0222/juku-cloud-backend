# 教科が9科目
CLASS_SUBJECTS_COUNT = 9
# 教科を作成
CLASS_SUBJECTS_COUNT.times { |i| ClassSubject.find_or_create_by!(name: i) }

# 曜日が7つ
AVAILABLE_DAYS_COUNT = 7
# 曜日を作成
AVAILABLE_DAYS_COUNT.times { |i| AvailableDay.find_or_create_by!(name: i) }
# 1人の管理者が担当する先生の数
TEACHERS_COUNT = 10

# 1人目の管理者が担当する先生の初めの番号
FIRST_TEACHER_START_NUMBER = 1
# 2人目の管理者が担当する先生の初めの番号
SECOND_TEACHER_START_NUMBER = FIRST_TEACHER_START_NUMBER + TEACHERS_COUNT

# ユーザーを作成するメソッド
def create_user(email, name, role, employment_status, school)
  User.find_or_create_by!(email: email) do |user|
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
  School.find_or_create_by!(school_code: school_code) do |school|
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
    teachers << teacher
  end
end

STUDENT_STATUSES = %i[active graduated quit paused] # 0: active, 1: graduated, 2: quit, 3: paused
SCHOOL_STAGES = %i[elementary_school junior_high_school high_school] # 0: elementary_school, 1: junior_high_school, 2: high_school
GRADES = [ 1, 2, 3 ] # 1 ~ 3 年生

# 生徒を作成するメソッド
def create_students_for_teacher(teachers, school_code, num_students = 2)
  teachers.each do |teacher|
    num_students.times do |i|
      status = STUDENT_STATUSES[i % STUDENT_STATUSES.size]
      school_stage = SCHOOL_STAGES[i % SCHOOL_STAGES.size]
      grade = GRADES[i % GRADES.size]

      student =
        Student.create!(
          name: Faker::Name.name,
          school: School.find_by!(school_code: school_code),
          status: status,
          joined_on: Time.current,
          school_stage: school_stage,
          grade: grade,
          desired_school: Faker::University.name
        )

      # 中間テーブル
      Teaching::Assignment.find_or_create_by!(user: teacher, student: student)
    end
  end
end

def pick_some(arr, min:, max:)
  count = rand(min..[ max, arr.size ].min)
  arr.sample(count)
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

# 科目(5教科)と曜日を取得して配列化
subjects = ClassSubject.order(:id).limit(5).to_a
days = AvailableDay.all.to_a

# 管理者と講師を対象にランダム割り当て
User
  .where(role: %i[admin teacher])
  .each do |user|
    user.class_subjects = pick_some(subjects, min: 1, max: 3)
    user.available_days = pick_some(days, min: 1, max: 4)
    user.save!
  end
