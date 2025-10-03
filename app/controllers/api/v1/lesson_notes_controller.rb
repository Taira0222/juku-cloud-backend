class Api::V1::LessonNotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_school!
  before_action :ensure_student_access!

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

  private

  def index_params
    params.permit(:studentId, :searchKeyword, :sortBy, :page, :perPage)
  end
end
