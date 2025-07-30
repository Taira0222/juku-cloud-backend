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
#  encrypted_password     :string           default(""), not null
#  grade                  :integer
#  graduated_university   :string
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  name                   :string           default(""), not null
#  provider               :string           default("email"), not null
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  role                   :integer          default("teacher"), not null
#  school_stage           :integer
#  sign_in_count          :integer          default(0), not null
#  tokens                 :json
#  uid                    :string           default(""), not null
#  unconfirmed_email      :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  school_id              :bigint
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_school_id             (school_id)
#  index_users_on_uid_and_provider      (uid,provider) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (school_id => schools.id)
#
class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable, :confirmable
  include DeviseTokenAuth::Concerns::User
  attr_accessor :confirm_success_url
  has_one :owned_school, class_name: "School", foreign_key: :owner_id # Admin が所有する塾
  belongs_to :school, optional: true # admin がschool_id 不要のため optional: true にする


  validates :name, presence: true, length: { maximum: 50 }
  enum :role, { teacher: 0, admin: 1 }, suffix: true # _suffix: true にすることでほかのメソッドと衝突しないようにする(例: user.teacher? ではなく user.teacher_role? を使用)
  validates :role, presence: true
  enum :school_stage, { bachelor: 0, master: 1 }, suffix: true # _suffix: true にすることでほかのメソッドと衝突しないようにする(例: user.bachelor? ではなく user.bachelor_school_stage? を使用)
end
