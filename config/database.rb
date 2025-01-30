# frozen_string_literal: true

begin
  require_relative '../.env.rb'
rescue LoadError
end

require 'yaml'
require 'erb'
require 'sequel/core'

# Load database configuration
db_config_file = File.join(File.dirname(__FILE__), 'database.yml')
db_config = YAML.safe_load(ERB.new(File.read(db_config_file)).result, aliases: true)
env = ENV.fetch('RACK_ENV', 'development')
config = db_config[env]

# Create database URL
database_url = ENV['DATABASE_URL'] || begin
  password = ENV['DATABASE_PASSWORD'].to_s
  password_part = password.empty? ? '' : ":#{password}"
  "postgres://postgres#{password_part}@#{config['host']}/#{config['database']}"
end

# Connect to database
DB = Sequel.connect(database_url)

# Load Sequel Database/Global extensions here
DB.extension :pg_auto_parameterize if DB.adapter_scheme == :postgres && Sequel::Postgres::USES_PG
DB.extension :pg_json
