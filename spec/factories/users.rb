FactoryBot.define do
  factory :user do
    name { "Test User" }
    email { "test@example.com" }
    password { "password" }
    password_confirmation { 'password' }
    role { :teacher }
    school_stage { :bachelor }
    grade { 1 }
    graduated_university { "University of Example" }
  end
end
