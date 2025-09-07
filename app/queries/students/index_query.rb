module Students
  # 定数なのでfreezeしておく
  ASSOCS = [
    :class_subjects,
    :available_days,
    { teachers: %i[teachable_subjects workable_days] }
  ].freeze
  class IndexQuery
    def self.call(school:, index_params:)
      search_keyword = index_params[:searchKeyword]
      school_stage = index_params[:school_stage]
      grade = index_params[:grade]
      page = index_params[:page]
      per_page = index_params[:perPage]

      students = school.students

      # 検索キーワードによる絞り込み（名前での部分一致）
      if search_keyword.present?
        students = students.where("name ILIKE ?", "%#{search_keyword}%")
      end
      # 学校段階による絞り込み
      if school_stage.present?
        students = students.where(school_stage: school_stage)
      end
      # 学年による絞り込み
      students = students.where(grade: grade) if grade.present?

      students.includes(Students::ASSOCS).order(:id).page(page).per(per_page)
    end
  end
end
