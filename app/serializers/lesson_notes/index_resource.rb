module LessonNotes
  class IndexResource < BaseResource
    one :created_by, resource: Dashboards::UserForDashboardResource
    one :last_updated_by, resource: Dashboards::UserForDashboardResource
    one :student_class_subject, resource: Shared::StudentClassSubjectResource
  end
end
