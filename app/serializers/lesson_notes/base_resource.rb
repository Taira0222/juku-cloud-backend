module LessonNotes
  class BaseResource
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
  end
end
