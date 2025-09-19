module Students
  class CreateService
    def self.call(school:, create_params:)
      new(school, create_params).call
    end

    def initialize(school, create_params)
      @school = school
      @params = create_params
    end

    def call
      student = nil
      ActiveRecord::Base.transaction do
        student = create_student!

        Students::RelationSetter.call(
          student: student,
          subject_ids: @params[:subject_ids],
          available_day_ids: @params[:available_day_ids],
          assignments: @params[:assignments]
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
  end
end
