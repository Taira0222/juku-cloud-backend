module Students
  class CreateService
    Result = Data.define(:ok?, :value, :errors)

    def self.call(school:, create_params:)
      new(school, create_params).call
    end

    def initialize(school, create_params)
      @school = school
      @params = create_params
    end

    def call
      student = nil
      # upsert_all はActiveRecord を通らずtimestamp が入らないので、自前で設定
      now = Time.current

      ActiveRecord::Base.transaction do
        student =
          Student.create!(
            name: @params[:name],
            status: @params[:status],
            school_stage: @params[:school_stage],
            grade: @params[:grade],
            joined_on: @params[:joined_on],
            desired_school: @params[:desired_school],
            school: @school
          )

        # subjects
        if @params[:subject_ids].present?
          rows =
            @params[:subject_ids].map do |sid|
              {
                student_id: student.id,
                class_subject_id: sid,
                created_at: now,
                updated_at: now
              }
            end
          # 通常の関連付けだと3回クエリを発行してしまうので、upsert_all で一括登録
          Subjects::StudentLink.upsert_all(
            rows,
            unique_by: %i[student_id class_subject_id]
          )
        end

        # days
        if @params[:available_day_ids].present?
          rows =
            @params[:available_day_ids].map do |d_id|
              {
                student_id: student.id,
                available_day_id: d_id,
                created_at: now,
                updated_at: now
              }
            end
          Availability::StudentLink.upsert_all(
            rows,
            unique_by: %i[student_id available_day_id]
          )
        end

        if @params[:assignments].blank?
          raise ArgumentError,
                I18n.t("students.errors.create_service.assignments_empty")
        end
        links_by_cs_id =
          student
            .student_class_subjects
            .where(class_subject_id: @params[:subject_ids])
            .pluck(:class_subject_id, :id)
            .to_h

        assign_rows =
          @params[:assignments].map do |assignment|
            {
              student_class_subject_id: links_by_cs_id[assignment[:subject_id]],
              user_id: assignment[:teacher_id],
              available_day_id: assignment[:day_id],
              created_at: now,
              updated_at: now
            }
          end
        Teaching::Assignment.upsert_all(
          assign_rows,
          unique_by: %i[student_class_subject_id user_id available_day_id]
        )
      end

      Result[true, student, []]
    rescue ActiveRecord::RecordInvalid => e
      # ActiveRecordのバリデーションエラー -> 422用に整形
      Result[false, nil, normalize_ar_errors(e.record)]
    rescue ActiveRecord::RecordNotFound => e
      Result[false, nil, [ { code: "VALIDATION_FAILED", message: e.message } ]]
    rescue ArgumentError => e
      Result[false, nil, [ { code: "VALIDATION_FAILED", message: e.message } ]]
    end

    private

    def normalize_ar_errors(record)
      if record.errors.blank?
        return [
          {
            code: "VALIDATION_FAILED",
            message: I18n.t("students.errors.create_service.unknown_validation")
          }
        ]
      end

      record.errors.map do |attr, msg|
        { code: "VALIDATION_FAILED", field: attr, message: msg }
      end
    end
  end
end
