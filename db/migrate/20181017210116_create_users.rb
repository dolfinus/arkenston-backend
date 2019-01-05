class CreateUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
      t.string   :name,               null: false, default: ''
      t.string   :email,              null: false, default: ''
      t.string   :encrypted_password, null: false, default: ''
      t.string   :remember_token,     null: false, default: ''
      t.string   :confirmation_token
      t.integer  :role
      t.timestamps
    end

    reversible do |dir|
      dir.up do
        User.create_translation_table! first_name: :string, middle_name: :string, last_name: :string
        change_column_null :user_translations, :first_name,  false, ''
        change_column_null :user_translations, :middle_name, false, ''
        change_column_null :user_translations, :last_name,   false, ''
      end

      dir.down do
        User.drop_translation_table!
      end
    end

    add_index :users, :name,               unique: true
    add_index :users, :email,              unique: true
    add_index :users, :confirmation_token, unique: true
    add_index :users, :remember_token,     unique: true
    add_index :users, [:id, :name, :role]
  end
end
