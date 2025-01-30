# frozen_string_literal: true

require 'yaml'
require 'erb'
require_relative '.env'
require 'fileutils'

module RakeHelpers
  module_function

  def db_config
    @db_config ||= begin
      yaml = ERB.new(File.read('config/database.yml')).result
      YAML.safe_load(yaml, aliases: true)[ENV.fetch('RACK_ENV', 'development')]
    end
  end

  def postgres_admin_connection
    "postgres://postgres:#{ENV['POSTGRES_PASSWORD']}@#{db_config['host']}/postgres"
  end

  def set_environment(env)
    ENV['RACK_ENV'] = env || ENV['RACK_ENV'] || 'development'
  end

  def timestamp
    Time.now.strftime('%Y%m%d%H%M%S')
  end

  def underscore(string)
    string.gsub(/::/, '/')
      .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
      .gsub(/([a-z\d])([A-Z])/, '\1_\2')
      .tr('-', '_')
      .downcase
  end
end

namespace :generate do
  include RakeHelpers

  desc 'Generate a new migration file'
  task :migration, [:name] do |_, args|
    abort('Please specify migration name (e.g., rake generate:migration[CreateUsers])') if args[:name].nil?

    name = args[:name]
    timestamp = RakeHelpers.timestamp
    filename = File.join('config/migrations', "#{timestamp}_#{underscore(name)}.rb")
    
    # Ensure migrations directory exists
    FileUtils.mkdir_p('config/migrations')

    # Create migration file
    File.open(filename, 'w') do |f|
      f.write <<~RUBY
        # frozen_string_literal: true

        Sequel.migration do
          change do
            # Add migration code here
          end
        end
      RUBY
    end

    puts "Created migration: #{filename}"
  end
end

namespace :db do
  include RakeHelpers

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
    set_environment(args[:env])
    version = args[:version]&.to_i

    require_relative './config/database'
    require 'logger'
    Sequel.extension :migration
    
    DB.loggers << Logger.new($stdout) if DB.loggers.empty?
    Sequel::Migrator.apply(DB, 'config/migrations', version)
  end

  desc 'Load the seed data from config/seeds.rb'
  task :seed, [:env] do |_, args|
    set_environment(args[:env])
    require_relative 'config/application'
    Application.boot
    require_relative 'config/seeds'
  end

  desc 'Reset database (migrate down, up, and seed)'
  task :reset, [:env] do |_, args|
    set_environment(args[:env])
    %w[migrate reenable migrate seed].each do |task|
      if task == 'migrate'
        Rake::Task['db:migrate'].invoke(ENV['RACK_ENV'], task == args[0] ? 0 : nil)
      elsif task == 'reenable'
        Rake::Task['db:migrate'].reenable
      else
        Rake::Task["db:#{task}"].invoke(ENV['RACK_ENV'])
      end
    end
  end

  desc 'Force reset database (warning: skips missing migrations)'
  task :force_reset, [:env] do |_, args|
    set_environment(args[:env])
    require_relative 'config/database'
    
    DB.tables.each { |table| DB.drop_table(table, cascade: true) }
    
    DB.create_table?(:schema_migrations) do
      column :filename, String, null: false
      primary_key [:filename]
    end

    Sequel.extension :migration
    Sequel::Migrator.apply(DB, 'config/migrations')

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
      task(:up)    { Rake::Task['db:migrate'].invoke(env) }
      
      desc "Migrate #{env} database all the way down"
      task(:down)  { Rake::Task['db:migrate'].invoke(env, 0) }
      
      desc "Migrate #{env} database down and back up"
      task :bounce do
        Rake::Task['db:migrate'].invoke(env, 0)
        Rake::Task['db:migrate'].reenable
        Rake::Task['db:migrate'].invoke(env)
      end
      
      desc "Reset #{env} database (migrate down, up, and seed)"
      task(:reset) { Rake::Task['db:reset'].invoke(env) }
      
      desc "Force reset #{env} database"
      task(:force_reset) { Rake::Task['db:force_reset'].invoke(env) }
    end
  end
end

desc 'Annotate Sequel models'
task :annotate do
  ENV['RACK_ENV'] = 'development'
  require_relative 'config/application'

  require 'zeitwerk'
  loader = Zeitwerk::Loader.new
  loader.push_dir("#{__dir__}/app/models")
  loader.setup

  DB.loggers.clear
  require 'sequel/annotate'

  Dir['app/models/**/*.rb'].sort.each { |model_file| require_relative model_file }
  Sequel::Annotate.annotate(Dir['app/models/**/*.rb'])
end

desc 'Start an interactive console'
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

task default: :test
