module Teachers
  class ForStudentResource
    include Alba::Resource
    attributes :id, :name, :role

    many :teachable_subjects, resource: Shared::ClassSubjectResource
    many :workable_days, resource: Shared::AvailableDayResource
  end
end
