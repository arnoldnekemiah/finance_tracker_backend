# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_08_30_161711) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "account_type", null: false
    t.string "account_number"
    t.string "bank_name"
    t.string "currency", default: "USD"
    t.text "description"
    t.boolean "is_active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "original_currency", default: "USD"
    t.integer "original_amount_cents"
    t.integer "balance_cents", default: 0, null: false
    t.index ["is_active"], name: "index_accounts_on_is_active"
    t.index ["original_currency"], name: "index_accounts_on_original_currency"
    t.index ["user_id", "account_type"], name: "index_accounts_on_user_id_and_account_type"
    t.index ["user_id"], name: "index_accounts_on_user_id"
  end

  create_table "budgets", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "start_date"
    t.datetime "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "category_id"
    t.string "period"
    t.string "original_currency", default: "USD"
    t.integer "original_amount_cents"
    t.decimal "exchange_rate", precision: 10, scale: 6
    t.integer "limit_cents", default: 0, null: false
    t.integer "spent_cents", default: 0, null: false
    t.index ["category_id"], name: "index_budgets_on_category_id"
    t.index ["original_currency"], name: "index_budgets_on_original_currency"
    t.index ["user_id"], name: "index_budgets_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.string "icon"
    t.string "color"
    t.string "transaction_type", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "parent_category_id"
    t.index ["parent_category_id"], name: "index_categories_on_parent_category_id"
    t.index ["user_id"], name: "index_categories_on_user_id"
  end

  create_table "debts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.string "creditor", null: false
    t.text "description"
    t.date "due_date", null: false
    t.string "status", default: "pending", null: false
    t.string "debt_type", null: false
    t.decimal "interest_rate", precision: 5, scale: 2
    t.boolean "is_recurring", default: false
    t.string "recurring_period"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "original_currency", default: "USD"
    t.integer "original_amount_cents"
    t.index ["due_date"], name: "index_debts_on_due_date"
    t.index ["original_currency"], name: "index_debts_on_original_currency"
    t.index ["user_id", "status"], name: "index_debts_on_user_id_and_status"
    t.index ["user_id"], name: "index_debts_on_user_id"
  end

  create_table "saving_goals", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title"
    t.decimal "target_amount"
    t.decimal "current_amount"
    t.datetime "target_date"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "original_currency", default: "USD"
    t.integer "original_amount_cents"
    t.index ["original_currency"], name: "index_saving_goals_on_original_currency"
    t.index ["user_id"], name: "index_saving_goals_on_user_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "category_id"
    t.string "transaction_type"
    t.datetime "date"
    t.text "description"
    t.string "recurring_id"
    t.string "payment_method"
    t.bigint "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "original_currency", default: "USD"
    t.integer "original_amount_cents"
    t.text "notes"
    t.index ["account_id"], name: "index_transactions_on_account_id"
    t.index ["category_id"], name: "index_transactions_on_category_id"
    t.index ["date"], name: "index_transactions_on_date"
    t.index ["original_currency"], name: "index_transactions_on_original_currency"
    t.index ["user_id"], name: "index_transactions_on_user_id"
  end

  create_table "user_analytics", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "event_type", null: false
    t.json "event_data", default: {}, null: false
    t.string "ip_address"
    t.text "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_user_analytics_on_created_at"
    t.index ["event_type"], name: "index_user_analytics_on_event_type"
    t.index ["user_id", "created_at"], name: "index_user_analytics_on_user_id_and_created_at"
    t.index ["user_id", "event_type"], name: "index_user_analytics_on_user_id_and_event_type"
    t.index ["user_id"], name: "index_user_analytics_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "jti", null: false
    t.string "first_name"
    t.string "last_name"
    t.boolean "active", default: true, null: false
    t.boolean "admin", default: false
    t.string "preferred_currency", default: "USD", null: false
    t.string "timezone", default: "UTC"
    t.index ["active"], name: "index_users_on_active"
    t.index ["admin"], name: "index_users_on_admin"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["preferred_currency"], name: "index_users_on_preferred_currency"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "accounts", "users"
  add_foreign_key "budgets", "categories"
  add_foreign_key "budgets", "users"
  add_foreign_key "categories", "categories", column: "parent_category_id"
  add_foreign_key "categories", "users"
  add_foreign_key "debts", "users"
  add_foreign_key "saving_goals", "users"
  add_foreign_key "transactions", "accounts"
  add_foreign_key "transactions", "categories"
  add_foreign_key "transactions", "users"
  add_foreign_key "user_analytics", "users"
end
