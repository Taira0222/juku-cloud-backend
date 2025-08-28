class Teachers::IndexPresenter
  def initialize(result)
    @current = result[:current]
    @teachers = result[:teachers]
  end
  # *は引数を無視するため
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
          only: %i[id name status school_stage grade]
        },
        class_subjects: {
          only: %i[id name]
        },
        available_days: {
          only: %i[id name]
        }
      },
      methods: %i[current_sign_in_at]
    )
  end
end
