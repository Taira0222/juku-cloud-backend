module Teachers
  class Validator
    # 返却用の軽量Resultオブジェクト
    Result = Data.define(:ok?, :teacher, :status, :error)

    def self.call(id:)
      teacher = User.find_by(id: id)
      unless teacher
        return (
          Result.new(
            false,
            nil,
            :not_found,
            I18n.t("teachers.errors.not_found")
          )
        )
      end

      # 誤ってadminを削除できないようにする
      if teacher.admin_role?
        return (
          Result.new(
            false,
            teacher,
            :forbidden,
            I18n.t("teachers.errors.delete.admin")
          )
        )
      end

      Result.new(true, teacher, :ok, nil)
    end
  end
end
