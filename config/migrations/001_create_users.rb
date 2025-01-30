# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:users) do
      primary_key :id

      String :email, null: false
      String :username, null: false
      String :password_digest, null: false
      String :timezone
      jsonb :options, default: '{}'
      jsonb :settings, default: '{}'
      String :status, default: 'active'
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      String :info
      String :reset_password_token
      DateTime :reset_password_sent_at
      String :confirmation_token
      DateTime :confirmed_at
      DateTime :confirmation_sent_at
      String :unconfirmed_email
      Integer :failed_attempts, default: 0, null: false
      String :unlock_token, null: false, default: Sequel.function(:gen_random_uuid)
      DateTime :locked_at, default: Sequel::CURRENT_TIMESTAMP

      index :confirmation_token, unique: true
      index :email, unique: true
      index :reset_password_token, unique: true
      index :status
      index :unconfirmed_email, unique: true
      index :unlock_token, unique: true
      index :username, unique: true
    end
  end
end
