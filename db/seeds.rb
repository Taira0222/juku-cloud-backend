# 重複作成を防ぐためにfind_or_create_by!を使用
admin = User.find_or_create_by!(email: "admin@example.com") do |user|
  user.name = "Admin User"
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
