module Teachers
  class BaseResource
    include Alba::Resource
    attributes :id,
               :provider,
               :uid,
               :allow_password_change,
               :name,
               :role,
               :email,
               :created_at,
               :updated_at,
               :school_id,
               :employment_status,
               :current_sign_in_at
  end
end
