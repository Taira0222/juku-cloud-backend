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
      student = @school.students.find(@raw[:id]) # 失敗→RecordNotFound

      ActiveRecord::Base.transaction do
        update_student!(student) # 失敗→RecordInvalid

        Students::RelationSetter.call(
          student: student,
          subject_ids: @raw[:subject_ids],
          available_day_ids: @raw[:available_day_ids],
          assignments: @raw[:assignments]
        )
      end

      student.id
    end

    private

    def update_student!(student)
      student.update!(
        name: @raw[:name],
        status: @raw[:status],
        school_stage: @raw[:school_stage],
        grade: @raw[:grade],
        joined_on: @raw[:joined_on],
        desired_school: @raw[:desired_school],
        school: @school
      )
    end
  end
end
