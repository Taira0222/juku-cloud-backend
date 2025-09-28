module Shared
  class LessonNoteResource
    include Alba::Resource

    attributes :id,
               :title,
               :description,
               :note_type,
               :created_by_name,
               :last_updated_by_name,
               :expire_date,
               :created_at,
               :updated_at

    one :created_by, resource: Dashboards::UserForDashboardResource
    one :last_updated_by, resource: Dashboards::UserForDashboardResource
    one :student_class_subject, resource: Shared::StudentClassSubjectResource
  end
end
