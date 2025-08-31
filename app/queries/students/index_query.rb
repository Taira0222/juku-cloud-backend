class Students::IndexQuery
  # 定数なのでfreezeしておく
  ASSOCS = [
    :class_subjects,
    :available_days,
    { teachers: %i[teachable_subjects workable_days] }
  ].freeze

  def self.call(school:, page:, per_page:)
    students =
      Student
        .where(school: school)
        .includes(ASSOCS)
        .order(:id)
        .page(page)
        .per(per_page)
  end
end
