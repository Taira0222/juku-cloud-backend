module Dashboards
  class ShowQuery
    # 定数なのでfreezeしておく
    ASSOCS = [
      :student_traits,
      { student_class_subjects: :class_subject },
      lesson_notes: [
        :created_by,
        :last_updated_by,
        { student_class_subject: :class_subject }
      ]
    ].freeze

    def self.call(school:, id:)
      student = school.students.preload(ASSOCS).find(id)
    end
  end
end
