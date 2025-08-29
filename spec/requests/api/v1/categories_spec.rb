require 'rails_helper'

RSpec.describe "Api::V1::Categories", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user) }

  describe "GET /api/v1/categories" do
    it "returns a success response" do
      get "/api/v1/categories", headers: headers
      puts response.body
      expect(response).to be_successful
    end
  end

  describe "POST /api/v1/categories/bulk_create" do
    let(:valid_attributes) do
      {
        categories: [
          { name: "Groceries", transaction_type: "expense" },
          { name: "Salary", transaction_type: "income" }
        ]
      }
    end

    it "creates multiple categories" do
      expect {
        post "/api/v1/categories/bulk_create", params: valid_attributes, headers: headers, as: :json
      }.to change(Category, :count).by(2)
      expect(response).to have_http_status(:created)
    end
  end

  describe "PATCH /api/v1/categories/bulk_update" do
    let!(:category1) { create(:category, user: user, name: "Old Name 1") }
    let!(:category2) { create(:category, user: user, name: "Old Name 2") }
    let(:valid_attributes) do
      {
        categories: [
          { id: category1.id, name: "New Name 1" },
          { id: category2.id, name: "New Name 2" }
        ]
      }
    end

    it "updates multiple categories" do
      patch "/api/v1/categories/bulk_update", params: valid_attributes, headers: headers, as: :json
      expect(response).to be_successful
      expect(category1.reload.name).to eq("New Name 1")
      expect(category2.reload.name).to eq("New Name 2")
    end
  end

  describe "DELETE /api/v1/categories/bulk_destroy" do
    let!(:category1) { create(:category, user: user) }
    let!(:category2) { create(:category, user: user) }
    let(:valid_attributes) do
      {
        category_ids: [category1.id, category2.id]
      }
    end

    it "deletes multiple categories" do
      expect {
        delete "/api/v1/categories/bulk_destroy", params: valid_attributes, headers: headers, as: :json
      }.to change(Category, :count).by(-2)
      expect(response).to be_successful
    end
  end

  describe "PATCH /api/v1/categories/move_transactions" do
    let!(:category1) { create(:category, user: user) }
    let!(:category2) { create(:category, user: user) }
    let!(:transaction) { create(:transaction, user: user, category: category1) }
    let(:valid_attributes) do
      {
        move_transactions: {
          from_category_id: category1.id,
          to_category_id: category2.id
        }
      }
    end

    it "moves transactions from one category to another" do
      patch "/api/v1/categories/move_transactions", params: valid_attributes, headers: headers, as: :json
      expect(response).to be_successful
      expect(transaction.reload.category_id).to eq(category2.id)
    end
  end
end
