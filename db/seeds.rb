# 重複作成を防ぐためにfind_or_create_by!を使用
admin = User.find_or_create_by!(email: "admin@example.com") do |user|
  user.name = "Admin User"
  user.password = "password"
  user.password_confirmation = "password"
  user.confirmed_at = Time.current
  user.confirmation_sent_at = Time.current
  user.role = :admin
end

# 追加の管理者ユーザーを作成
another_admin = User.find_or_create_by!(email: "another_admin@example.com") do |user|
  user.name = "Another Admin User"
  user.password = "password"
  user.password_confirmation = "password"
  user.confirmed_at = Time.current
  user.confirmation_sent_at = Time.current
  user.role = :admin
end

School.find_or_create_by!(school_code: "ABC123") do |school|
  school.name = "First School"
  school.owner = admin
end


School.find_or_create_by!(school_code: "DEF123") do |school|
  school.name = "Second School"
  school.owner = another_admin
end


# First School と Second School に属するteacherをそれぞれ10人ずつ作成
10.times do |i|
  User.find_or_create_by!(email: "teacher#{i + 1}@example.com") do |teacher|
    teacher.name = "Teacher #{i + 1}"
    teacher.password = "password"
    teacher.password_confirmation = "password"
    teacher.confirmed_at = Time.current
    teacher.confirmation_sent_at = Time.current
    teacher.school = School.find_by!(school_code: "ABC123")
    teacher.role = :teacher
  end

  User.find_or_create_by!(email: "teacher#{i + 11}@example.com") do |teacher|
    teacher.name = "Teacher #{i + 11}"
    teacher.password = "password"
    teacher.password_confirmation = "password"
    teacher.confirmed_at = Time.current
    teacher.confirmation_sent_at = Time.current
    teacher.school = School.find_by!(school_code: "DEF123")
    teacher.role = :teacher
  end
end
