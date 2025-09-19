module Students
  class IndexResource < BaseResource
    many :class_subjects, resource: Shared::ClassSubjectResource
    many :available_days, resource: Shared::AvailableDayResource
    many :teachers, resource: Teachers::ForStudentResource

    attribute :teaching_assignments do |student|
      student.teaching_assignments.map do |ta|
        {
          teacher_id: ta.user.id,
          subject_id: ta.student_class_subject.class_subject.id,
          day_id: ta.available_day.id
        }
      end
    end
  end
end
