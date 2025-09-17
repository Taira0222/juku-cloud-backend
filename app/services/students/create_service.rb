module Students
  class CreateService
    def self.call(school:, create_params:)
      new(school, create_params).call
    end

    def initialize(school, create_params)
      @school = school
      @params = create_params
      @now = Time.current
    end

    def call
      student = nil
      ActiveRecord::Base.transaction do
        student = create_student!

        # --- subjects ---
        # 文字列から整数に変換
        subject_ids = @params[:subject_ids].map(&:to_i).uniq

        if subject_ids.blank?
          raise ArgumentError,
                I18n.t("students.errors.create_service.subject_ids_empty")
        end

        # 存在確認
        found_subject_ids = ClassSubject.where(id: subject_ids).pluck(:id)
        missing = subject_ids - found_subject_ids
        if missing.any?
          raise ActiveRecord::RecordNotFound,
                I18n.t("students.errors.create_service.missing_subject_ids")
        end

        upsert_student_subject_links!(student.id, found_subject_ids)

        # --- available_days ---
        day_ids = @params[:available_day_ids].map(&:to_i).uniq
        if day_ids.blank?
          raise ArgumentError,
                I18n.t("students.errors.create_service.available_day_ids_empty")
        end

        # 存在確認
        found_day_ids = AvailableDay.where(id: day_ids).pluck(:id)
        missing_days = day_ids - found_day_ids
        if missing_days.any?
          raise ActiveRecord::RecordNotFound,
                I18n.t(
                  "students.errors.create_service.missing_available_day_ids"
                )
        end

        upsert_student_day_links!(student.id, found_day_ids)

        # --- assignments ---
        assignments = @params[:assignments]
        if assignments.blank?
          raise ArgumentError,
                I18n.t("students.errors.create_service.assignments_empty")
        end

        links_by_cs_id =
          student
            .student_class_subjects
            .where(class_subject_id: found_subject_ids)
            .pluck(:class_subject_id, :id) # pluck は指定したカラムだけの配列を返す
            .to_h

        assign_rows =
          assignments.map do |a|
            sid = a[:subject_id].to_i
            tid = a[:teacher_id].to_i
            did = a[:day_id].to_i

            scs_id = links_by_cs_id[sid]
            # Assignment の subject_id が student がリンクしている教科に含まれていない場合はエラー
            unless scs_id
              raise ArgumentError,
                    I18n.t(
                      "students.errors.assignment.subject_not_linked",
                      subject_id: sid
                    )
            end

            # teacher / day の存在確認
            unless User.exists?(id: tid)
              raise ActiveRecord::RecordNotFound,
                    I18n.t("students.errors.assignment.missing_teacher")
            end
            unless found_day_ids.include?(did)
              raise ActiveRecord::RecordNotFound,
                    I18n.t("students.errors.assignment.missing_day")
            end
            {
              student_class_subject_id: scs_id,
              user_id: tid,
              available_day_id: did,
              created_at: @now,
              updated_at: @now
            }
          end
        Teaching::Assignment.upsert_all(
          assign_rows,
          unique_by: %i[student_class_subject_id user_id available_day_id]
        )
      end
      assos = Students::IndexQuery::ASSOCS

      # eager load 検知しないようにする
      ActiveRecord::Associations::Preloader.new(
        records: [ student ],
        associations: assos
      ).call

      student.reload
    end

    private

    def create_student!
      Student.create!(
        name: @params[:name],
        status: @params[:status],
        school_stage: @params[:school_stage],
        grade: @params[:grade],
        joined_on: @params[:joined_on],
        desired_school: @params[:desired_school],
        school: @school
      )
    end

    def upsert_student_subject_links!(student_id, subject_ids)
      rows =
        subject_ids.map do |sid|
          {
            student_id: student_id,
            class_subject_id: sid,
            created_at: @now,
            updated_at: @now
          }
        end
      Subjects::StudentLink.upsert_all(
        rows,
        unique_by: %i[student_id class_subject_id]
      )
    end

    def upsert_student_day_links!(student_id, day_ids)
      rows =
        day_ids.map do |d|
          {
            student_id: student_id,
            available_day_id: d,
            created_at: @now,
            updated_at: @now
          }
        end
      Availability::StudentLink.upsert_all(
        rows,
        unique_by: %i[student_id available_day_id]
      )
    end
  end
end
