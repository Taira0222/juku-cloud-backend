module Students
  class Validator
    def self.call(id:)
      student = Student.find_by(id: id)
      # find_by で意図的に独自のエラーメッセージを返すようにしている
      unless student
        raise ActiveRecord::RecordNotFound, I18n.t("students.errors.not_found")
      end

      student
    end
  end
end
