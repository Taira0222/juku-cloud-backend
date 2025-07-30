admin = User.create!(
  name: "Admin User",
  email: "admin@example.com",
  password: "password",
  password_confirmation: "password",
  confirmed_at: Time.current,
  confirmation_sent_at: Time.current,
  role: :admin
)

School.create!(
  name: "First School",
  school_code: "ABC123",
  owner: admin
)
