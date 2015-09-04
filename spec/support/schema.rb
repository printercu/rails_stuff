ActiveRecord::Schema.define do
  self.verbose = false

  create_table :users, force: true do |t|
    t.string :status, null: false
    t.string :subscription_status, null: false

    t.timestamps null: false
  end

  create_table :tokens, force: true do |t|
    t.string :code
    t.index :code, unique: true

    t.timestamps null: false
  end
end
