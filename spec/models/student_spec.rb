# == Schema Information
#
# Table name: students
#
#  id             :bigint           not null, primary key
#  desired_school :string
#  grade          :integer          not null
#  joined_on      :date
#  left_on        :date
#  name           :string           not null
#  school_stage   :integer          not null
#  status         :integer          default("active"), not null
#  student_code   :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  school_id      :bigint           not null
#
# Indexes
#
#  index_students_on_school_id     (school_id)
#  index_students_on_student_code  (student_code) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (school_id => schools.id)
#
require 'rails_helper'

RSpec.describe Student, type: :model do
  describe 'validation' do
    let(:student) { build(:student) }

    it 'is valid with valid attributes' do
      expect(student).to be_valid
    end

    it 'is not valid without a student_code' do
      student.student_code = nil
      allow(student).to receive(:set_student_code) # コールバックを無効化
      expect(student).not_to be_valid
    end

    it 'is not valid with a student_code with wrong format' do
      student.student_code = '12345' # Assuming the format requires alphanumeric characters
      allow(student).to receive(:set_student_code) # コールバックを無効化
      expect(student).not_to be_valid
    end

    it 'is not valid with a duplicate student_code' do
      create(:student, student_code: 'S0001') # DB に保存
      allow(student).to receive(:set_student_code) # コールバックを無効化
      student.student_code = 'S0001' # メモリのstudent にS0001を設定

      expect(student).not_to be_valid
    end

    it 'is not valid without a name' do
      student.name = nil
      expect(student).not_to be_valid
    end

    it 'is not valid with 51 characters in name' do
      student.name = 'a' * 51
      expect(student).not_to be_valid
    end

    it 'is not valid without status' do
      student.status = nil
      expect(student).not_to be_valid
    end

    it 'is not valid without joined_on date' do
      student.joined_on = nil
      expect(student).not_to be_valid
    end

    it 'should not be later than or equal to left_on date' do
      student.left_on = Date.yesterday
      student.joined_on = Date.today
      expect(student).not_to be_valid
      expect(student.errors[:left_on]).to include('は入塾日以降の日付である必要があります')
    end

    it 'is not valid without a school_stage' do
      student.school_stage = nil
      expect(student).not_to be_valid
    end

    it 'is not valid without a grade' do
      student.grade = nil
      expect(student).not_to be_valid
    end

    it 'is not valid with 101 characters in desired_school' do
      student.desired_school = 'a' * 101
      expect(student).not_to be_valid
    end
  end

  describe 'student_code auto-generation' do
    it 'automatically generates sequential student_code when creating students' do
      # 既存データをクリア
      Student.destroy_all

      # 順番に学生を作成（student_codeは自動生成される）
      student1 = create(:student)
      student2 = create(:student)
      student3 = create(:student)

      # 自動生成された student_code のフォーマットを確認
      expect(student1.student_code).to match(/\AS\d{4}\z/)
      expect(student2.student_code).to match(/\AS\d{4}\z/)
      expect(student3.student_code).to match(/\AS\d{4}\z/)

      # 一意性を確認
      codes = [ student1.student_code, student2.student_code, student3.student_code ]
      expect(codes.uniq.length).to eq(3)
    end
  end

  describe 'associations' do
    let(:association) do
      described_class.reflect_on_association(target)
    end

    context 'school association' do
      let(:target) { :school }
      it "belongs to school" do
        expect(association.macro).to eq :belongs_to
        expect(association.class_name).to eq 'School'
      end
    end

    context 'teaching_assignments association' do
      let(:target) { :teaching_assignments }
      it "has many teaching_assignments" do
        expect(association.macro).to eq :has_many
        expect(association.class_name).to eq 'TeachingAssignment'
        expect(association.options[:dependent]).to eq :destroy
      end
    end

    context 'users association' do
      let(:target) { :users }
      it "has many users through teaching_assignments" do
        expect(association.macro).to eq :has_many
        expect(association.class_name).to eq 'User'
      end
    end
  end
end
