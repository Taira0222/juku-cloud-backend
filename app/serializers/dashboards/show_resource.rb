module Dashboards
  class ShowResource < Students::BaseResource
    has_many :class_subjects, resource: Shared::ClassSubjectResource
  end
end
