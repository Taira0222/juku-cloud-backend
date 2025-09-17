module Teachers
  class Validator
    def self.call(id:)
      teacher = User.find_by(id: id)
      # teacherが存在しない場合は404
      unless teacher
        raise ActiveRecord::RecordNotFound, I18n.t("teachers.errors.not_found")
      end

      # 誤ってadminを削除できないようにする
      if teacher.admin_role?
        raise ForbiddenError, I18n.t("teachers.errors.delete.admin")
      end

      teacher
    end
  end
end
