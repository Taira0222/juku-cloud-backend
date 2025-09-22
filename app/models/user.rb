# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  allow_password_change  :boolean          default(FALSE)
#  confirmation_sent_at   :datetime
#  confirmation_token     :string
#  confirmed_at           :datetime
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  email                  :string           default(""), not null
#  employment_status      :integer          default("active"), not null
#  encrypted_password     :string           default(""), not null
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  name                   :string           default(""), not null
#  provider               :string           default("email"), not null
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  role                   :integer          default("teacher"), not null
#  sign_in_count          :integer          default(0), not null
#  tokens                 :json
#  uid                    :string           default(""), not null
#  unconfirmed_email      :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  invite_id              :bigint
#  school_id              :bigint
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_invite_id             (invite_id)
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_school_id             (school_id)
#  index_users_on_uid_and_provider      (uid,provider) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (invite_id => invites.id)
#  fk_rails_...  (school_id => schools.id)
#
class User < ActiveRecord::Base
  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :trackable,
         :confirmable
  include DeviseTokenAuth::Concerns::User
  attr_accessor :confirm_success_url
  has_one :owned_school, class_name: "School", foreign_key: :owner_id
  # admin がschool_id = nil なので、optional: true にする
  belongs_to :school, optional: true

  has_many :teaching_assignments,
           class_name: "Teaching::Assignment",
           dependent: :destroy
  has_many :student_class_subjects,
           class_name: "Subjects::StudentLink",
           through: :teaching_assignments
  #  "Subjects::StudentLink" は科目と一緒に生徒を持つので生徒が重複しないように distinct をつける
  has_many :students, -> { distinct }, through: :student_class_subjects

  has_many :user_class_subjects,
           class_name: "Subjects::UserLink",
           dependent: :destroy
  has_many :teachable_subjects,
           through: :user_class_subjects,
           source: :class_subject
  # teachable_subjects のエイリアス
  has_many :class_subjects, through: :user_class_subjects

  has_many :user_available_days,
           class_name: "Availability::UserLink",
           dependent: :destroy
  has_many :workable_days, through: :user_available_days, source: :available_day
  # workable_days のエイリアス
  has_many :available_days, through: :user_available_days
  # User:Invite 1:1 adminはinvite なしで作成予定
  belongs_to :invite, optional: true

  # user.teacher_role? で判定できるようにする
  enum :role, { teacher: 0, admin: 1 }, suffix: true
  enum :employment_status, { active: 0, inactive: 1, on_leave: 2 }, suffix: true

  validates :name, presence: true, length: { maximum: 50 }
  # role はteacher or admin のみ受け付ける
  validates :role, presence: true, inclusion: { in: roles.keys }
  validates :employment_status, presence: true

  # devise_token_auth のメソッドをオーバーライド
  def token_validation_response
    base = super
    if teacher_role?
      base.merge(school: school&.as_json(only: %i[id name]))
    else
      admin_school = School.find_by(owner_id: id)
      base.merge(school: admin_school&.as_json(only: %i[id name]))
    end
  end

  def admin?
    role == "admin"
  end
end
