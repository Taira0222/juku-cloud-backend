module Students
  class IndexQuery
    # 定数なのでfreezeしておく
    ASSOCS = [
      :class_subjects,
      :available_days,
      { teachers: %i[teachable_subjects workable_days] },
      {
        teaching_assignments: [
          :available_day,
          :user,
          { student_class_subject: :class_subject }
        ]
      }
    ].freeze

    def self.call(school:, index_params:, current_user:)
      search_keyword = index_params[:searchKeyword]
      school_stage = index_params[:school_stage]
      grade = index_params[:grade]
      page = index_params[:page]
      per_page = index_params[:perPage]

      students = school.students

      # 検索キーワードによる絞り込み（名前での部分一致）
      if search_keyword.present?
        # SQLインジェクション対策
        kw = ActiveRecord::Base.sanitize_sql_like(search_keyword.to_s.strip)
        students = students.where("name ILIKE ?", "%#{kw}%")
      end
      # 学校段階による絞り込み
      if school_stage.present?
        students = students.where(school_stage: school_stage)
      end
      # 学年による絞り込み
      students = students.where(grade: grade) if grade.present?

      # 管理者でない場合は、自分が担当している生徒のみに絞り込む
      unless current_user.admin_role?
        students =
          students
            .joins(:teaching_assignments)
            .where(teaching_assignments: { user_id: current_user.id })
            .distinct
      end

      students.includes(ASSOCS).order(:id).page(page).per(per_page)
    end
  end
end
