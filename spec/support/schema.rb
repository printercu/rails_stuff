ActiveRecord::Schema.define do
  self.verbose = false

  create_table :users, force: true do |t|
    t.string :name, null: false
    t.string :email, null: false
    t.boolean :admin, null: false, default: false

    t.timestamps null: false
  end

  create_table :projects, force: true do |t|
    t.string :name, null: false
    t.belongs_to :user, null: false, foreign_key: true, index: true
    t.string :type, null: false, index: true

    t.string :department
    t.string :company

    t.timestamps null: false
  end

  create_table :customers, force: true do |t|
    t.string :status, null: false
    t.string :subscription_status, null: false

    t.timestamps null: false
  end

  create_table :orders, force: true do |t|
    t.integer :status, null: false
    t.integer :delivery_status, null: false
    t.integer :delivery_method, null: false

    t.timestamps null: false
  end

  create_table :tokens, force: true do |t|
    t.string :code
    t.index :code, unique: true

    t.timestamps null: false
  end
end
