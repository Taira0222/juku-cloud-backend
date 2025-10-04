module LessonNotes
  class CreateService
    def self.call(student_class_subject:, current_user:, create_params:)
      new(student_class_subject, current_user, create_params).call
    end

    def initialize(student_class_subject, current_user, create_params)
      @student_class_subject = student_class_subject
      @current_user = current_user
      @params = create_params
    end

    def call
      lesson_note = create_lesson_note!(@student_class_subject)
      lesson_note.reload
    end

    private

    def create_lesson_note!(scs)
      LessonNote.create!(
        title: @params[:title],
        description: @params[:description],
        note_type: @params[:note_type],
        expire_date: @params[:expire_date],
        student_class_subject: scs,
        created_by: @current_user,
        created_by_name: @current_user.name
      )
    end
  end
end
