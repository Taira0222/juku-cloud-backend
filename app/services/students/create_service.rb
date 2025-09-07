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
        if @params[:subject_ids].blank?
          raise ArgumentError,
                I18n.t("students.errors.create_service.subject_ids_empty")
        end

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

        # available_days
        if @params[:available_day_ids].blank?
          raise ArgumentError,
                I18n.t("students.errors.create_service.available_day_ids_empty")
        end
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

        # assignments
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
      Result[false, nil, normalize_ar_errors(e.record)]
    rescue ArgumentError => e
      Result[false, nil, [ { code: "VALIDATION_FAILED", message: e.message } ]]
    rescue => e
      Rails.logger.error(e.full_message)
      Result[
        false,
        nil,
        [
          {
            code: "VALIDATION_FAILED",
            message: I18n.t("students.errors.create_service.unknown_validation")
          }
        ]
      ]
    end

    private

    # フロント用にエラーメッセージを整形
    def normalize_ar_errors(record)
      record.errors.map do |error|
        {
          code: "VALIDATION_FAILED",
          field: (error.attribute == :base ? nil : error.attribute),
          message: error.full_message
        }
      end
    end
  end
end
