# 教科が9科目
CLASS_SUBJECTS_COUNT = 9
# 教科を作成
CLASS_SUBJECTS_COUNT.times do |i|
  ClassSubject.find_or_create_by!(name: i)
end

# 曜日が7つ
AVAILABLE_DAYS_COUNT = 7
# 曜日を作成
AVAILABLE_DAYS_COUNT.times do |i|
  AvailableDay.find_or_create_by!(name: i)
end

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


STUDENT_STATUSES = [ :active, :graduated, :quit, :paused ] # 0: active, 1: graduated, 2: quit, 3: paused
SCHOOL_STAGES = [ :elementary_school, :junior_high_school, :high_school ] # 0: elementary_school, 1: junior_high_school, 2: high_school
GRADES = [ 1, 2, 3 ] # 1 ~ 3 年生

# 生徒を作成するメソッド
def create_students_for_teacher(teachers, school_code, num_students = 2)
  teachers.each do |teacher|
    num_students.times do |i|
      status = STUDENT_STATUSES[i % STUDENT_STATUSES.size]
      school_stage = SCHOOL_STAGES[i % SCHOOL_STAGES.size]
      grade = GRADES[i % GRADES.size]

      student = Student.create!(
        name: Faker::Name.name,
        school: School.find_by!(school_code: school_code),
        status: status,
        joined_on: Time.current,
        school_stage: school_stage,
        grade: grade,
        desired_school: Faker::University.name,
      )

      # 中間テーブル
      Teaching::Assignment.find_or_create_by!(
        user: teacher,
        student: student,
      ) do |assignment|
        assignment.started_on = Time.current
        assignment.teaching_status = true
      end
    end
  end
end


def pick_some(arr, min:, max:)
  count = rand(min..[ max, arr.size ].min)
  arr.sample(count)
end


# 管理者を作成
admin = create_user("admin@example.com", "Admin User", :admin, :active, nil)
another_admin = create_user("another_admin@example.com", "Another Admin User", :admin, :active, nil)

# 塾を作成
first_school = create_school("ABC123", "First School", admin)
second_school = create_school("DEF123", "Second School", another_admin)

# 先生たちを配列に貯める
first_teachers  = []
second_teachers = []

TEACHERS_COUNT = 10
TEACHERS_COUNT.times do |i|
  employment_status = i < 5 ? :active : :inactive # 最初の5人はactive, 残りはinactive

  first_teachers << create_user("teacher#{i + 1}@example.com", "Teacher #{i + 1}", :teacher, employment_status, first_school)
  second_teachers << create_user("teacher#{i + 11}@example.com", "Teacher #{i + 11}", :teacher, employment_status, second_school)
end

# 生徒を2人ずつ作成
create_students_for_teacher(first_teachers, "ABC123")
create_students_for_teacher(second_teachers, "DEF123")

# 科目(5教科)と曜日を取得して配列化
subjects = ClassSubject.order(:id).limit(5).to_a
days = AvailableDay.all.to_a

# 管理者と講師を対象にランダム割り当て
User.where(role: [ :admin, :teacher ]).each do |user|
  user.class_subjects = pick_some(subjects, min: 1, max: 3)
  user.available_days = pick_some(days, min: 1, max: 4)
  user.save!
end
