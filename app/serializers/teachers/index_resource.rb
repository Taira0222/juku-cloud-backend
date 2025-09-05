module Teachers
  class IndexResource < BaseResource
    many :students, resource: Students::ForTeacherResource
    many :class_subjects, resource: Shared::ClassSubjectResource
    many :available_days, resource: Shared::AvailableDayResource
  end
end
