ActiveRecord::Schema.define do
  self.verbose = false

  create_table :tokens, force: true do |t|
    t.string :code
    t.index :code, unique: true

    t.timestamps null: false
  end
end
