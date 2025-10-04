module LessonNotes
  class Updater
    def self.call(student_class_subject:, current_user:, update_params:)
      new(student_class_subject, current_user, update_params).call
    end

    def initialize(student_class_subject, current_user, update_params)
      @student_class_subject = student_class_subject
      @current_user = current_user
      @params = update_params
    end

    def call
      lesson_note = @student_class_subject.lesson_notes.find(@params[:id])
      update_lesson_note!(lesson_note)
    end

    private

    def update_lesson_note!(lesson_note)
      lesson_note.update!(
        title: @params[:title],
        description: @params[:description],
        note_type: @params[:note_type],
        expire_date: @params[:expire_date],
        last_updated_by: @current_user,
        last_updated_by_name: @current_user.name
      )
      lesson_note
    end
  end
end
