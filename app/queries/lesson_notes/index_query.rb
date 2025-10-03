module LessonNotes
  class IndexQuery
    # 定数なのでfreezeしておく
    ASSOCS = [
      :created_by,
      :last_updated_by,
      { student_class_subject: :class_subject }
    ].freeze

    SORT_OPTIONS = {
      "expire_date_asc" => {
        expire_date: :asc
      },
      "expire_date_desc" => {
        expire_date: :desc
      }
    }.freeze

    def self.call(school:, index_params:)
      student_id = index_params[:studentId]
      search_keyword = index_params[:searchKeyword]
      sort_by = index_params[:sortBy]
      page = index_params[:page]
      per_page = index_params[:perPage]

      lesson_notes = school.students.find(student_id).lesson_notes

      # 検索キーワードによる絞り込み（名前での部分一致）
      if search_keyword.present?
        # SQLインジェクション対策
        kw = ActiveRecord::Base.sanitize_sql_like(search_keyword.to_s.strip)
        lesson_notes = lesson_notes.where("title ILIKE ?", "%#{kw}%")
      end
      # safe リストに入れて、安全にしてからソート条件を適用
      order_option = SORT_OPTIONS[sort_by.to_s]
      lesson_notes =
        if order_option
          lesson_notes.order(order_option)
        else
          # フォールバック(デフォルト)はID順
          lesson_notes.order(:id)
        end

      lesson_notes.includes(ASSOCS).page(page).per(per_page)
    end
  end
end
