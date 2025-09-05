module Students
  class IndexResource < BaseResource
    many :class_subjects, resource: Shared::ClassSubjectResource
    many :available_days, resource: Shared::AvailableDayResource
    many :teachers, resource: Teachers::ForStudentResource
  end
end
