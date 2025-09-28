module Shared
  class StudentClassSubjectResource
    include Alba::Resource
    attributes :id
    one :class_subject, resource: Shared::ClassSubjectResource
  end
end
