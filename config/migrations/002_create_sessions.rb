# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:sessions) do
      primary_key :id
      foreign_key :user_id, :users, null: false
      String :token, null: false, default: Sequel.function(:gen_random_uuid)
      String :user_agent
      Inet :ip_address
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, null: false, default: Sequel::CURRENT_TIMESTAMP

      index :token, unique: true
      index :user_id
    end
  end
end
