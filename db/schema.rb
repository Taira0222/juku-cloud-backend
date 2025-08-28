# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_08_27_234532) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "available_days", force: :cascade do |t|
    t.integer "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "class_subjects", force: :cascade do |t|
    t.integer "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "invites", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.string "token_digest", null: false
    t.integer "role", default: 0, null: false
    t.integer "max_uses", default: 1, null: false
    t.integer "uses_count", default: 0, null: false
    t.datetime "expires_at", null: false
    t.datetime "used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id"], name: "index_invites_on_school_id"
    t.index ["token_digest"], name: "index_invites_on_token_digest", unique: true
  end

  create_table "schools", force: :cascade do |t|
    t.bigint "owner_id", null: false
    t.string "name", null: false
    t.string "school_code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_schools_on_owner_id"
    t.index ["school_code"], name: "index_schools_on_school_code", unique: true
  end

  create_table "student_available_days", force: :cascade do |t|
    t.bigint "student_id", null: false
    t.bigint "available_day_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["available_day_id"], name: "index_student_available_days_on_available_day_id"
    t.index ["student_id", "available_day_id"], name: "idx_on_student_id_available_day_id_b42ed887dc", unique: true
    t.index ["student_id"], name: "index_student_available_days_on_student_id"
  end

  create_table "student_class_subjects", force: :cascade do |t|
    t.bigint "student_id", null: false
    t.bigint "class_subject_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["class_subject_id"], name: "index_student_class_subjects_on_class_subject_id"
    t.index ["student_id", "class_subject_id"], name: "idx_on_student_id_class_subject_id_c0e296835a", unique: true
    t.index ["student_id"], name: "index_student_class_subjects_on_student_id"
  end

  create_table "students", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.string "student_code", null: false
    t.string "name", null: false
    t.integer "status", default: 0, null: false
    t.date "joined_on"
    t.date "left_on"
    t.integer "school_stage", null: false
    t.integer "grade", null: false
    t.string "desired_school"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id"], name: "index_students_on_school_id"
    t.index ["student_code"], name: "index_students_on_student_code", unique: true
  end

  create_table "teaching_assignments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "student_class_subject_id", null: false
    t.index ["student_class_subject_id", "user_id"], name: "index_teaching_assignments_on_scs_and_user", unique: true
    t.index ["student_class_subject_id"], name: "index_teaching_assignments_on_student_class_subject_id"
    t.index ["user_id"], name: "index_teaching_assignments_on_user_id"
  end

  create_table "user_available_days", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "available_day_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["available_day_id"], name: "index_user_available_days_on_available_day_id"
    t.index ["user_id", "available_day_id"], name: "index_user_available_days_on_user_id_and_available_day_id", unique: true
    t.index ["user_id"], name: "index_user_available_days_on_user_id"
  end

  create_table "user_class_subjects", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "class_subject_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["class_subject_id"], name: "index_user_class_subjects_on_class_subject_id"
    t.index ["user_id", "class_subject_id"], name: "index_user_class_subjects_on_user_id_and_class_subject_id", unique: true
    t.index ["user_id"], name: "index_user_class_subjects_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "provider", default: "email", null: false
    t.string "uid", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.boolean "allow_password_change", default: false
    t.datetime "remember_created_at"
    t.string "name", default: "", null: false
    t.integer "role", default: 0, null: false
    t.string "email", default: "", null: false
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.json "tokens"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.bigint "school_id"
    t.integer "employment_status", default: 0, null: false
    t.bigint "invite_id"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invite_id"], name: "index_users_on_invite_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["school_id"], name: "index_users_on_school_id"
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
  end

  add_foreign_key "invites", "schools"
  add_foreign_key "schools", "users", column: "owner_id"
  add_foreign_key "student_available_days", "available_days"
  add_foreign_key "student_available_days", "students"
  add_foreign_key "student_class_subjects", "class_subjects"
  add_foreign_key "student_class_subjects", "students"
  add_foreign_key "students", "schools"
  add_foreign_key "teaching_assignments", "student_class_subjects"
  add_foreign_key "teaching_assignments", "users"
  add_foreign_key "user_available_days", "available_days"
  add_foreign_key "user_available_days", "users"
  add_foreign_key "user_class_subjects", "class_subjects"
  add_foreign_key "user_class_subjects", "users"
  add_foreign_key "users", "invites"
  add_foreign_key "users", "schools"
end
