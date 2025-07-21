class TeacherGradeUpdater
  def self.run
    today = Date.current
    return unless today.month == 4 && today.day == 1

    User.teacher_role.find_each do |user|
      next unless user.bachelor_school_stage? || user.master_school_stage?

      # 大学院2年生は進級しない
      next if user.master_school_stage? && user.grade == 2
      # 大学4年生は大学を卒業して大学院に進学する
      if user.bachelor_school_stage? && user.grade == 4
        user.update(grade: 1, school_stage: :master)
      # 学年を1つ上げる
      else
        user.update(grade: user.grade + 1)
      end
    end
  end
end
