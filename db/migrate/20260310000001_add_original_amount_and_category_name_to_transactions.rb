class AddOriginalAmountAndCategoryNameToTransactions < ActiveRecord::Migration[7.1]
  def change
    add_column :transactions, :original_amount, :decimal, precision: 15, scale: 2
    add_column :transactions, :category_name, :string

    # Backfill existing records: set original_amount from original_amount_cents or amount
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE transactions
          SET original_amount = COALESCE(original_amount_cents / 100.0, amount)
          WHERE original_amount IS NULL;
        SQL

        execute <<-SQL
          UPDATE transactions
          SET category_name = categories.name
          FROM categories
          WHERE transactions.category_id = categories.id
            AND transactions.category_name IS NULL;
        SQL
      end
    end
  end
end
