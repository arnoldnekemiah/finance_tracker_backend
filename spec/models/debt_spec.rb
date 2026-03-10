# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Debt, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:amount) }
    it { should validate_presence_of(:creditor) }
    it { should validate_presence_of(:due_date) }
    it { should validate_inclusion_of(:status).in_array(%w[pending paid overdue]) }
  end
end
