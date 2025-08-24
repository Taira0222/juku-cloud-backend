module Teachers
  class Updater
    # errors は配列で返す
    Result = Data.define(:ok?, :teacher, :errors)

    def self.call(teacher:, attrs:)
      new(teacher, attrs).call
    end

    def initialize(teacher, attrs)
      @teacher = teacher
      @raw = attrs
    end

    def call
      base, subject_ids, day_ids, student_ids = extract(@raw)

      # 更新操作
      ActiveRecord::Base.transaction do
        @teacher.update!(base)
        @teacher.class_subject_ids = subject_ids if subject_ids
        @teacher.available_day_ids = day_ids if day_ids
        @teacher.student_ids = student_ids if student_ids
      end

      # 成功時の結果を返す
      Result.new(true, @teacher.reload, [])
    rescue ActiveRecord::RecordInvalid => e
      Result.new(false, @teacher, e.record.errors.full_messages)
    rescue ArgumentError => e # enum無効値など
      Result.new(false, @teacher, [ I18n.t("teachers.errors.invalid_argument") ])
    end

    private

    def extract(p)
      # 空の値は更新しない
      base = p.slice(:name, :employment_status).compact_blank
      # 配列の値は重複とnilを除去し、空の配列はそのまま返す
      subject_ids = extract_ids(p[:subject_ids])
      day_ids = extract_ids(p[:available_day_ids])
      student_ids = extract_ids(p[:student_ids])
      # subject_ids, day_ids, student_ids が空の場合は nil を返す
      [ base, subject_ids.presence, day_ids.presence, student_ids.presence ]
    end

    def extract_ids(val)
      Array(val).compact.uniq
    end
  end
end
