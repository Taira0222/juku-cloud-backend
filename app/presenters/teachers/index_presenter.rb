class Teachers::IndexPresenter
  def initialize(result)
    @current = result[:current]
    @teachers = result[:teachers]
  end

  def as_json(*)
    {
      current_user: format_user(@current),
      teachers: @teachers.map { |teacher| format_user(teacher) }
    }
  end

  private

  def format_user(user)
    user.as_json(
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
  end
end
