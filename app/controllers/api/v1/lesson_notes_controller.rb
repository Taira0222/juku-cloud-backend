class Api::V1::LessonNotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_school!
  before_action :ensure_student_access!
  before_action :get_student_class_subject, only: %i[create update]

  # GET /api/v1/lesson_notes
  def index
    lesson_notes =
      LessonNotes::IndexQuery.call(school: @school, index_params: index_params)
    render json: {
             lesson_notes:
               LessonNotes::IndexResource.new(lesson_notes).serializable_hash,
             meta: {
               total_pages: lesson_notes.total_pages,
               total_count: lesson_notes.total_count,
               current_page: lesson_notes.current_page,
               per_page: lesson_notes.limit_value
             }
           },
           status: :ok
  end

  # POST /api/v1/lesson_notes
  def create
    lesson_note =
      LessonNotes::CreateService.call(
        current_user: current_user,
        student_class_subject: @student_class_subject,
        create_params: create_params
      )
    render json: LessonNotes::CreateResource.new(lesson_note).serializable_hash,
           status: :created
  end

  # PATCH/PUT /api/v1/lesson_notes/:id
  def update
    lesson_note =
      LessonNotes::Updater.call(
        student_class_subject: @student_class_subject,
        current_user: current_user,
        update_params: update_params
      )
    render json: LessonNotes::UpdateResource.new(lesson_note).serializable_hash,
           status: :ok
  end

  private

  def index_params
    params.permit(
      :student_id,
      :subject_id,
      :searchKeyword,
      :sortBy,
      :page,
      :perPage
    )
  end

  def base_params
    %i[student_id subject_id title description note_type expire_date]
  end

  def create_params
    params.permit(*base_params)
  end

  def update_params
    params.permit(:id, *base_params)
  end

  def get_student_class_subject
    params = create_params || update_params
    @student_class_subject =
      LessonNotes::Validator.call(school: @school, create_params: params)
  end
end
