module Students
  class Validator
    def self.call(id:)
      student = Student.find_by(id: id)
      # studentが存在しない場合は404
      unless student
        raise ActiveRecord::RecordNotFound, I18n.t("students.errors.not_found")
      end

      student
    end
  end
end
