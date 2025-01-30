# frozen_string_literal: true

# Migrate

# Up migrations
# rake db:test:up
# rake db:development:up
# rake db:production:up

# # Down migrations
# rake db:test:down
# rake db:development:down

# # Bounce migrations
# rake db:test:bounce
# rake db:development:bounce

# # Or use the general migrate task with arguments
# rake db:migrate[development]
# rake db:migrate[test,0]

require 'yaml'
require 'erb'
require_relative '.env'

namespace :db do
  def db_config
    @db_config ||= begin
      yaml = ERB.new(File.read('config/database.yml')).result
      YAML.safe_load(yaml, aliases: true)[ENV.fetch('RACK_ENV', 'development')]
    end
  end

  def postgres_admin_connection
    "postgres://postgres:#{ENV['POSTGRES_PASSWORD']}@#{db_config['host']}/postgres"
  end

  desc 'Create the database'
  task :create do
    puts "Creating database: #{db_config['database']}"
    `psql #{postgres_admin_connection} -c "CREATE DATABASE #{db_config['database']}"`
    puts "Database #{db_config['database']} created."
  rescue StandardError => e
    puts "Failed to create database: #{e.message}"
  end

  desc 'Drop the database'
  task :drop do
    puts "Dropping database: #{db_config['database']}"
    `psql #{postgres_admin_connection} -c "DROP DATABASE IF EXISTS #{db_config['database']}"`
    puts "Database #{db_config['database']} dropped."
  rescue StandardError => e
    puts "Failed to drop database: #{e.message}"
  end

  desc 'Run database migrations'
  task :migrate, [:env, :version] do |_, args|
    env = args[:env] || ENV['RACK_ENV'] || 'development'
    version = args[:version]&.to_i
    ENV['RACK_ENV'] = env
    require_relative './config/database'
    require 'logger'
    Sequel.extension :migration
    DB.loggers << Logger.new($stdout) if DB.loggers.empty?
    Sequel::Migrator.apply(DB, 'config/migrations', version)
  end

  desc 'Load the seed data from config/seeds.rb'
  task :seed, [:env] do |_, args|
    env = args[:env] || ENV['RACK_ENV'] || 'development'
    ENV['RACK_ENV'] = env
    require_relative 'config/application'
    Application.boot
    require_relative 'config/seeds'
  end

  desc 'Reset database (migrate down, up, and seed)'
  task :reset, [:env] do |_, args|
    env = args[:env] || ENV['RACK_ENV'] || 'development'
    Rake::Task['db:migrate'].invoke(env, 0)
    Rake::Task['db:migrate'].reenable
    Rake::Task['db:migrate'].invoke(env)
    Rake::Task['db:seed'].invoke(env)
  end

  desc 'Force reset database (warning: skips missing migrations)'
  task :force_reset, [:env] do |_, args|
    env = args[:env] || ENV['RACK_ENV'] || 'development'
    ENV['RACK_ENV'] = env
    require_relative 'config/database'
    # Drop all tables
    DB.tables.each do |table|
      DB.drop_table(table, cascade: true)
    end
    # Reset schema_migrations
    DB.create_table?(:schema_migrations) do
      column :filename, String, null: false
      primary_key [:filename]
    end
    # Run migrations fresh
    Sequel.extension :migration
    Sequel::Migrator.apply(DB, 'config/migrations')
    # Run seeds if they exist
    if File.exist?('config/seeds.rb')
      require_relative 'config/application'
      Application.boot
      require_relative 'config/seeds'
    end
  end

  # Environment specific tasks
  %w[test development production].each do |env|
    namespace env do
      desc "Migrate #{env} database to latest version"
      task :up do
        Rake::Task['db:migrate'].invoke(env)
      end

      desc "Migrate #{env} database all the way down"
      task :down do
        Rake::Task['db:migrate'].invoke(env, 0)
      end

      desc "Migrate #{env} database down and back up"
      task :bounce do
        Rake::Task['db:migrate'].invoke(env, 0)
        Rake::Task['db:migrate'].reenable
        Rake::Task['db:migrate'].invoke(env)
      end

      desc "Reset #{env} database (migrate down, up, and seed)"
      task :reset do
        Rake::Task['db:reset'].invoke(env)
      end

      desc "Force reset #{env} database"
      task :force_reset do
        Rake::Task['db:force_reset'].invoke(env)
      end
    end
  end
end

# Other
desc 'Annotate Sequel models'
task 'annotate' do
  ENV['RACK_ENV'] = 'development'

  # Load the environment
  require_relative 'config/application'

  # Set up Zeitwerk to load models
  require 'zeitwerk'
  loader = Zeitwerk::Loader.new
  loader.push_dir("#{__dir__}/app/models")
  loader.setup

  DB.loggers.clear
  require 'sequel/annotate'

  # Load all models first
  Dir['app/models/**/*.rb'].sort.each do |model_file|
    require_relative model_file
  end

  Sequel::Annotate.annotate(Dir['app/models/**/*.rb'])
end

# Rakefile
task :console do
  require_relative 'config/application'
  Application.boot

  # Custom formatter that only shows real queries
  DB.loggers.first.formatter = proc do |severity, datetime, _progname, msg|
    if msg.is_a?(String) &&
       !msg.include?('pg_') &&
       !msg.include?('regclass') &&
       !msg.include?('server_version')
      "#{severity}, [#{datetime}] #{msg}\n"
    end
  end

  require 'irb'
  require 'irb/completion'

  def reload!
    puts 'Reloading...'
    Application.loader.reload
    true
  end

  ARGV.clear

  puts "Loading #{Application.env} console..."
  IRB.start(__FILE__)
end

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/*_test.rb']
  t.warning = false
end

# Makes 'rake test' the default task
task default: :test
