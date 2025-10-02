module Dashboards
  class ShowQuery
    # 定数なのでfreezeしておく
    ASSOCS = [ { student_class_subjects: :class_subject } ].freeze

    def self.call(school:, id:)
      student = school.students.preload(ASSOCS).find(id)
    end
  end
end
