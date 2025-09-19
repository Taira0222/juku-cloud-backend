module Students
  class SaveTransaction
    ASSOCS = Students::IndexQuery::ASSOCS
    class << self
      def run!(params)
        student =
          ActiveRecord::Base.transaction do
            s = yield # create! or update!
            Students::RelationSetter.call(
              student: s,
              subject_ids: params[:subject_ids],
              available_day_ids: params[:available_day_ids],
              assignments: params[:assignments]
            )
            s
          end
        # 変更を反映させる
        student.reload
        # eager load 検知しないようにする
        ActiveRecord::Associations::Preloader.new(
          records: [ student ],
          associations: ASSOCS
        ).call

        student
      end
    end
  end
end
