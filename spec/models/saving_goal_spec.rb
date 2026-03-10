# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SavingGoal, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:target_amount) }
  end
end
