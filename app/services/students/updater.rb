module Students
  class Updater
    def self.call(school:, update_params:)
      new(school, update_params).call
    end

    def initialize(school, params)
      @school = school
      @raw = params
    end

    def call
      Students::SaveTransaction.run!(@raw) do
        id = @raw[:id].to_i
        student = @school.students.find(id) # 失敗→RecordNotFound
        update_student!(student) # 失敗→RecordInvalid
      end
    end

    private

    def update_student!(student)
      student.update!(
        name: @raw[:name],
        status: @raw[:status],
        school_stage: @raw[:school_stage],
        grade: @raw[:grade],
        joined_on: @raw[:joined_on],
        desired_school: @raw[:desired_school]
      )
      student
    end
  end
end
