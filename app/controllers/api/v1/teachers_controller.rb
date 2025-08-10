class Api::V1::TeachersController < ApplicationController
  before_action :authenticate_user!

  def index
    # 先にエラーハンドリングを行う
    if current_user.teacher_role?
      # 403
      render json: { error: "講師はこの操作を行うことができません" }, status: :forbidden
      return
    end

    @school = School.find_by(owner_id: current_user.id)
    if @school.nil?
      # 404
      render json: { error: "学校が見つかりません" }, status: :not_found
      return
    end

    # ここから初めてプリロード（成功パスでのみ実行される）
    current =
      User
        .where(id: current_user.id)
        .preload(
          :students,
          :teaching_assignments,
          :class_subjects,
          :available_days
        )
        .first

    teachers =
      User.where(school: @school).preload(
        :students,
        :teaching_assignments,
        :class_subjects,
        :available_days
      )

    # current_user も講師を務める可能性があるので含める
    render json: {
             current_user:
               current.as_json(
                 include: {
                   students: {
                     only: %i[id student_code name status school_stage grade]
                   },
                   teaching_assignments: {
                     only: %i[id student_id user_id teaching_status]
                   },
                   class_subjects: {
                     only: %i[id name]
                   },
                   available_days: {
                     only: %i[id name]
                   }
                 },
                 methods: %i[last_sign_in_at current_sign_in_at]
               ),
             teachers:
               teachers.as_json(
                 include: {
                   students: {
                     only: %i[id student_code name status school_stage grade]
                   },
                   teaching_assignments: {
                     only: %i[id student_id user_id teaching_status]
                   },
                   class_subjects: {
                     only: %i[id name]
                   },
                   available_days: {
                     only: %i[id name]
                   }
                 },
                 methods: %i[last_sign_in_at current_sign_in_at]
               )
           },
           status: :ok
  end
end
