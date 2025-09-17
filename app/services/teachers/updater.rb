module Teachers
  class Updater
    def self.call(teacher:, attrs:)
      new(teacher, attrs).call
    end

    def initialize(teacher, attrs)
      @teacher = teacher
      @raw = attrs
    end

    def call
      base, subject_ids, day_ids = extract(@raw)

      ActiveRecord::Base.transaction do
        @teacher.update!(base) # 失敗→RecordInvalid
        @teacher.class_subject_ids = subject_ids if subject_ids
        @teacher.available_day_ids = day_ids if day_ids
      end

      @teacher.reload
    rescue ArgumentError
      raise ArgumentError, I18n.t("teachers.errors.invalid_argument")
    end

    private

    def extract(p)
      # 空の値は更新しない
      base = p.slice(:name, :employment_status).compact_blank
      # 配列の値は重複とnilを除去し、空の配列はそのまま返す
      subject_ids = extract_ids(p[:subject_ids])
      day_ids = extract_ids(p[:available_day_ids])
      # subject_ids, day_ids, student_ids が空の場合は nil を返す
      [ base, subject_ids.presence, day_ids.presence ]
    end

    def extract_ids(val)
      Array(val).compact.uniq
    end
  end
end
