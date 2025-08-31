class Students::IndexPresenter
  def initialize(students)
    @students = students
  end
  # *は引数を無視するため
  def as_json(*)
    {
      students: @students.map { |student| format_student(student) },
      meta: {
        total_pages: @students.total_pages,
        total_count: @students.total_count,
        current_page: @students.current_page,
        per_page: @students.limit_value
      }
    }
  end

  private

  def format_student(student)
    student.as_json(
      only: %i[id name status school_stage grade desired_school joined_on],
      include: {
        class_subjects: {
          only: %i[id name]
        },
        available_days: {
          only: %i[id name]
        },
        teachers: {
          only: %i[id name role],
          include: {
            teachable_subjects: {
              only: %i[id name]
            },
            workable_days: {
              only: %i[id name]
            }
          }
        }
      }
    )
  end
end
