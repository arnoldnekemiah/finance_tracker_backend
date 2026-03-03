class CreateSupportMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :support_messages do |t|
      t.references :user, null: false, foreign_key: true
      t.string     :subject
      t.text       :message
      t.string     :status
      t.timestamps
    end
  end
end
