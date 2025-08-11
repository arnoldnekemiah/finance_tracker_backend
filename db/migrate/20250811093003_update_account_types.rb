class UpdateAccountTypes < ActiveRecord::Migration[7.1]
  def up
    # Map old account types to new ones
    # bank, checking -> regular
    # savings -> savings (unchanged)
    # mobile_money, credit -> debt
    
    execute <<-SQL
      UPDATE accounts 
      SET account_type = 'regular' 
      WHERE account_type IN ('bank', 'checking');
    SQL
    
    execute <<-SQL
      UPDATE accounts 
      SET account_type = 'debt' 
      WHERE account_type IN ('mobile_money', 'credit');
    SQL
  end
  
  def down
    # Reverse mapping for rollback
    execute <<-SQL
      UPDATE accounts 
      SET account_type = 'bank' 
      WHERE account_type = 'regular';
    SQL
    
    execute <<-SQL
      UPDATE accounts 
      SET account_type = 'credit' 
      WHERE account_type = 'debt';
    SQL
  end
end
