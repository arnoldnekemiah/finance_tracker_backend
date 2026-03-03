class EnableExtensions < ActiveRecord::Migration[7.1]
  def change
    enable_extension "plpgsql"
  end
end
