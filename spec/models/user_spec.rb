# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should validate_uniqueness_of(:email).case_insensitive }
  end

  describe 'associations' do
    it { should have_many(:accounts).dependent(:destroy) }
    it { should have_many(:categories).dependent(:destroy) }
    it { should have_many(:transactions).dependent(:destroy) }
    it { should have_many(:budgets).dependent(:destroy) }
    it { should have_many(:debts).dependent(:destroy) }
    it { should have_many(:saving_goals).dependent(:destroy) }
  end

  describe 'callbacks' do
    it 'creates default categories after creation' do
      user = create(:user)
      expect(user.categories.count).to be > 0
    end

    it 'creates a default account after creation' do
      user = create(:user)
      expect(user.accounts.count).to eq(1)
    end
  end
end
