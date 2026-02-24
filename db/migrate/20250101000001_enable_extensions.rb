class EnableExtensions < ActiveRecord::Migration[7.1]
  def change
    enable_extension 'pgcrypto'
    enable_extension 'plpgsql'
  end
end
