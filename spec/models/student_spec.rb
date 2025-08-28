# == Schema Information
#
# Table name: students
#
#  id             :bigint           not null, primary key
#  desired_school :string
#  grade          :integer          not null
#  joined_on      :date
#  name           :string           not null
#  school_stage   :integer          not null
#  status         :integer          default("active"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  school_id      :bigint           not null
#
# Indexes
#
#  index_students_on_school_id  (school_id)
#
# Foreign Keys
#
#  fk_rails_...  (school_id => schools.id)
#
require "rails_helper"

RSpec.describe Student, type: :model do
  describe "validation" do
    let(:student) { build(:student) }

    it "is valid with valid attributes" do
      expect(student).to be_valid
    end

    it "is not valid without a name" do
      student.name = nil
      expect(student).not_to be_valid
    end

    it "is not valid with 51 characters in name" do
      student.name = "a" * 51
      expect(student).not_to be_valid
    end

    it "is not valid without status" do
      student.status = nil
      expect(student).not_to be_valid
    end

    it "is not valid without joined_on date" do
      student.joined_on = nil
      expect(student).not_to be_valid
    end

    it "is not valid without a school_stage" do
      student.school_stage = nil
      expect(student).not_to be_valid
    end

    it "is not valid without a grade" do
      student.grade = nil
      expect(student).not_to be_valid
    end

    it "is not valid with 101 characters in desired_school" do
      student.desired_school = "a" * 101
      expect(student).not_to be_valid
    end
  end

  describe "associations" do
    let(:association) { described_class.reflect_on_association(target) }

    context "school association" do
      let(:target) { :school }
      it "belongs to school" do
        expect(association.macro).to eq :belongs_to
        expect(association.class_name).to eq "School"
      end
    end

    context "teaching_assignments association" do
      let(:target) { :teaching_assignments }
      it "has many teaching_assignments" do
        expect(association.macro).to eq :has_many
        expect(association.class_name).to eq "Teaching::Assignment"
      end
    end

    context "teachers association" do
      let(:target) { :teachers }
      it "has many teachers through teaching_assignments" do
        expect(association.macro).to eq :has_many
        expect(association.class_name).to eq "User"
      end
    end

    context "student_class_subjects association" do
      let(:target) { :student_class_subjects }
      it "has many student_class_subjects" do
        expect(association.macro).to eq :has_many
        expect(association.class_name).to eq "Subjects::StudentLink"
        expect(association.options[:dependent]).to eq :destroy
      end
    end

    context "class_subjects association" do
      let(:target) { :class_subjects }
      it "has many class_subjects" do
        expect(association.macro).to eq :has_many
        expect(association.class_name).to eq "ClassSubject"
      end
    end

    context "student_available_days association" do
      let(:target) { :student_available_days }
      it "has many student_available_days" do
        expect(association.macro).to eq :has_many
        expect(association.class_name).to eq "Availability::StudentLink"
        expect(association.options[:dependent]).to eq :destroy
      end
    end

    context "available_days association" do
      let(:target) { :available_days }
      it "has many available_days" do
        expect(association.macro).to eq :has_many
        expect(association.class_name).to eq "AvailableDay"
      end
    end
  end
end
