module Dashboards
  class ShowResource < Students::BaseResource
    has_many :class_subjects, resource: Shared::ClassSubjectResource
    has_many :student_traits, resource: Shared::StudentTraitResource
    has_many :lesson_notes, resource: Shared::LessonNoteResource
  end
end
