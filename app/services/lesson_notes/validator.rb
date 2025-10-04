module LessonNotes
  class Validator
    def self.call(school:, params:)
      new(school, params).call
    end

    def initialize(school, params)
      @school = school
      @params = params
    end

    def call
      if @params.nil?
        raise ArgumentError,
              I18n.t("lesson_notes.errors.params_must_not_be_nil")
      end
      # student_class_subject を探す
      scs =
        Subjects::StudentLink.find_by(
          student_id: @params[:student_id],
          class_subject_id: @params[:subject_id]
        )

      if scs.nil?
        raise ArgumentError,
              I18n.t("lesson_notes.errors.student_class_subject_not_found")
      end

      scs
    end
  end
end
