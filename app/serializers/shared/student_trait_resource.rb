module Shared
  class StudentTraitResource
    include Alba::Resource
    attributes :id, :category, :title, :description, :created_at, :updated_at
  end
end
