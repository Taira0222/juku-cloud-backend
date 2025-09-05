module Students
  class BaseResource
    include Alba::Resource
    attributes :id,
               :name,
               :status,
               :school_stage,
               :grade,
               :desired_school,
               :joined_on
  end
end
