module Students
  class Updater
    def self.call(school:, update_params:)
      new(school, update_params).call
    end

    def initialize(school, params)
      @school = school
      @params = params
    end

    def call
      if @params.nil?
        raise ArgumentError, I18n.t("students.errors.params_must_not_be_nil")
      end
      Students::SaveTransaction.run!(@params) do
        id = @params[:id].to_i
        student = @school.students.find(id) # 失敗→RecordNotFound
        update_student!(student) # 失敗→RecordInvalid
      end
    end

    private

    def update_student!(student)
      student.update!(
        name: @params[:name],
        status: @params[:status],
        school_stage: @params[:school_stage],
        grade: @params[:grade],
        joined_on: @params[:joined_on],
        desired_school: @params[:desired_school]
      )
      student
    end
  end
end
