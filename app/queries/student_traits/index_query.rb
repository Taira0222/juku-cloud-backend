module StudentTraits
  class IndexQuery
    SORT_OPTIONS = {
      "created_at_asc" => {
        created_at: :asc
      },
      "created_at_desc" => {
        created_at: :desc
      },
      "updated_at_asc" => {
        updated_at: :asc
      },
      "updated_at_desc" => {
        updated_at: :desc
      }
    }.freeze

    def self.call(school:, index_params:)
      student_id = index_params[:student_id]
      search_keyword = index_params[:searchKeyword]
      sort_by = index_params[:sortBy]
      page = index_params[:page]
      per_page = index_params[:perPage]

      student_traits = school.students.find(student_id).student_traits

      # 検索キーワードによる絞り込み（名前での部分一致）
      if search_keyword.present?
        # SQLインジェクション対策
        kw = ActiveRecord::Base.sanitize_sql_like(search_keyword.to_s.strip)
        student_traits = student_traits.where("title ILIKE ?", "%#{kw}%")
      end
      # safe リストに入れて、安全にしてからソート条件を適用
      order_option = SORT_OPTIONS[sort_by.to_s]
      student_traits =
        if order_option
          student_traits.order(order_option)
        else
          # フォールバック(デフォルト)はID順
          student_traits.order(:id)
        end

      student_traits.page(page).per(per_page)
    end
  end
end
