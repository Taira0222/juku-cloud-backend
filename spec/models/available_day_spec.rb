# == Schema Information
#
# Table name: available_days
#
#  id         :bigint           not null, primary key
#  name       :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require 'rails_helper'

RSpec.describe AvailableDay, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
