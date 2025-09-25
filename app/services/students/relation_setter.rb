module Students
  class RelationSetter
    class << self
      def call(student:, subject_ids:, available_day_ids:, assignments:)
        now = Time.current

        ActiveRecord::Base.transaction do
          # 古い関連データを削除
          old_scs_ids =
            Subjects::StudentLink.where(student_id: student.id).pluck(:id)
          Teaching::Assignment.where(
            student_class_subject_id: old_scs_ids
          ).delete_all

          found_subject_ids = set_subjects(student, subject_ids, now: now)
          found_day_ids =
            set_available_days(student, available_day_ids, now: now)
          set_assignments(
            student,
            assignments,
            found_subject_ids,
            found_day_ids,
            now: now
          )
        end
      end

      private

      def set_subjects(student, subject_ids, now:)
        subject_ids = subject_ids.map(&:to_i).uniq

        if subject_ids.blank?
          raise ArgumentError, I18n.t("students.errors.subject_ids_empty")
        end

        # 存在確認
        found_subject_ids = ClassSubject.where(id: subject_ids).pluck(:id)
        missing = subject_ids - found_subject_ids
        if missing.any?
          raise ActiveRecord::RecordNotFound,
                I18n.t("students.errors.missing_subject_ids")
        end

        update_student_subject_links!(student.id, found_subject_ids, now: now)
        # return
        found_subject_ids
      end

      def set_available_days(student, available_day_ids, now:)
        day_ids = available_day_ids.map(&:to_i).uniq
        if day_ids.blank?
          raise ArgumentError, I18n.t("students.errors.available_day_ids_empty")
        end

        # 存在確認
        found_day_ids = AvailableDay.where(id: day_ids).pluck(:id)
        missing_days = day_ids - found_day_ids
        if missing_days.any?
          raise ActiveRecord::RecordNotFound,
                I18n.t("students.errors.missing_available_day_ids")
        end

        update_student_day_links!(student.id, found_day_ids, now: now)
        # return
        found_day_ids
      end

      def set_assignments(
        student,
        assignments,
        found_subject_ids,
        found_day_ids,
        now:
      )
        if assignments.blank?
          raise ArgumentError, I18n.t("students.errors.assignments_empty")
        end
        # student がリンクしている教科のidをキー、student_class_subject_idを値とするハッシュ
        links_by_cs_id =
          Subjects::StudentLink
            .where(student_id: student.id, class_subject_id: found_subject_ids)
            .pluck(:class_subject_id, :id)
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
                    I18n.t("students.errors.assignment.subject_not_linked")
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
              created_at: now,
              updated_at: now
            }
          end
        # studentの関連のある student_class_subjectのid を取得
        scs_ids = Subjects::StudentLink.where(student_id: student.id).pluck(:id)

        # トランザクションで一括削除・一括挿入
        Teaching::Assignment.transaction do
          Teaching::Assignment.where(
            student_class_subject_id: scs_ids
          ).delete_all
          Teaching::Assignment.insert_all(assign_rows) unless assign_rows.empty?
        end
      end

      def update_student_subject_links!(student_id, subject_ids, now:)
        rows =
          subject_ids.map do |sid|
            {
              student_id: student_id,
              class_subject_id: sid,
              created_at: now,
              updated_at: now
            }
          end
        # トランザクションで一括削除・一括挿入
        Subjects::StudentLink.transaction do
          Subjects::StudentLink.where(student_id: student_id).delete_all
          Subjects::StudentLink.insert_all(rows) unless rows.empty?
        end
      end

      def update_student_day_links!(student_id, day_ids, now:)
        rows =
          day_ids.map do |d|
            {
              student_id: student_id,
              available_day_id: d,
              created_at: now,
              updated_at: now
            }
          end
        # トランザクションで一括削除・一括挿入
        Availability::StudentLink.transaction do
          Availability::StudentLink.where(student_id: student_id).delete_all
          Availability::StudentLink.insert_all(rows) unless rows.empty?
        end
      end
    end
  end
end
