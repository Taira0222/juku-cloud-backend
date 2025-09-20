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
      if @params.nil?
        raise ArgumentError, I18n.t("students.errors.params_must_not_be_nil")
      end
      Students::SaveTransaction.run!(@params) { create_student! }
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
