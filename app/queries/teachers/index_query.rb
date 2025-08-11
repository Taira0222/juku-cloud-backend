class Teachers::IndexQuery
  # 定数なのでfreezeしておく
  ASSOCS = %i[
    students
    teaching_assignments
    class_subjects
    available_days
  ].freeze

  def self.call(current_user, school:)
    current = User.where(id: current_user.id).preload(ASSOCS).first!
    teachers = User.where(school: school).preload(ASSOCS).order(:id)
    { current:, teachers: }
  end
end
