# frozen_string_literal: true

require 'yaml'
require 'erb'
require 'fileutils'
require 'digest/md5'
require 'json'

namespace :assets do
  desc 'Fingerprint assets while preserving unchanged ones'
  task :precompile do
    # First, run your existing build process
    puts 'Building assets with esbuild and tailwind...'
    system('npm run build') || raise('Asset build failed')

    puts 'Fingerprinting assets...'

    # Configure paths
    assets_dir = 'public'
    manifest_path = "#{assets_dir}/manifest.json"

    # Load existing manifest if it exists
    old_manifest = File.exist?(manifest_path) ? JSON.parse(File.read(manifest_path)) : {}
    new_manifest = {}

    # Keeps track of old fingerprinted files we want to remove
    old_fingerprinted_files = []
    old_manifest.each_value do |filename|
      old_fingerprinted_files << "#{assets_dir}/#{filename}"
    end

    # Process all JS and CSS files
    Dir.glob("#{assets_dir}/**/*.{css,js}").each do |file|
      # Skip files that are already fingerprinted
      next if file =~ /-[a-f0-9]{8}\.(js|css)$/

      # Get relative path from assets_dir
      rel_path = file.sub("#{assets_dir}/", '')

      # Calculate content hash
      content_hash = Digest::MD5.file(file).hexdigest[0, 8]

      # Generate fingerprinted name
      ext = File.extname(file)
      base_name = File.basename(file, ext)
      dir_name = File.dirname(rel_path)
      fingerprinted_name = "#{base_name}-#{content_hash}#{ext}"

      # Full paths
      fingerprinted_rel_path = dir_name == '.' ? fingerprinted_name : "#{dir_name}/#{fingerprinted_name}"
      fingerprinted_full_path = "#{assets_dir}/#{fingerprinted_rel_path}"

      # Check if hash changed from previous version
      if old_manifest[rel_path]
        old_fingerprinted_path = "#{assets_dir}/#{old_manifest[rel_path]}"
        if old_fingerprinted_path =~ /-#{content_hash}\.(js|css)$/
          # Content hasn't changed, keep the old file
          fingerprinted_rel_path = old_manifest[rel_path]
          old_fingerprinted_files.delete(old_fingerprinted_path)
          puts " - #{rel_path} unchanged (keeping #{fingerprinted_rel_path})"
        else
          # Content changed, create new fingerprinted file
          FileUtils.cp(file, fingerprinted_full_path)
          puts " - #{rel_path} changed → #{fingerprinted_rel_path}"
        end
      else
        # New file, create fingerprinted version
        FileUtils.cp(file, fingerprinted_full_path)
        puts " - #{rel_path} → #{fingerprinted_rel_path}"
      end

      # Add to new manifest
      new_manifest[rel_path] = fingerprinted_rel_path
    end

    # Remove old fingerprinted files that aren't used anymore
    old_fingerprinted_files.each do |old_file|
      if File.exist?(old_file)
        File.delete(old_file)
        puts " - Removed unused #{old_file.sub("#{assets_dir}/", '')}"
      end
    end

    # Write updated manifest
    File.write(manifest_path, JSON.pretty_generate(new_manifest))
    puts "Asset fingerprinting complete. Manifest updated with #{new_manifest.size} entries."
  end
end

require_relative '.env' if ENV['RACK_ENV'] != 'production'

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

  def set_environment(env) # rubocop:disable Naming/AccessorMethodName
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
      task(:up) { Rake::Task['db:migrate'].invoke(env) }

      desc "Migrate #{env} database all the way down"
      task(:down) { Rake::Task['db:migrate'].invoke(env, 0) }

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

# This Rake task generates Phlex view files with proper namespace structure and optional initialization.
#
# Usage:
#   Without initialization arguments:
#     rake "generate:phlex[Products::Index]"
#     # Creates: app/views/products/index_view.rb
#     # Generated class: Products::IndexView < Phlex::HTML
#
#   With initialization arguments (space-separated after the comma):
#     rake "generate:phlex[Sessions::New,token errors current_user]"
#     # Creates: app/views/sessions/new_view.rb
#     # Generated class: Sessions::NewView < Phlex::HTML with initialize(token:, errors:, current_user:)
#
# Features:
#   - Handles nested namespaces (e.g., Admin::Products::Show)
#   - Creates directory structure automatically
#   - Adds frozen_string_literal comment
#   - Proper Ruby indentation
#   - Optional initialize method with multiple arguments
#
# Note:
#   When using namespaces (::), wrap the rake task in quotes to avoid shell interpretation:
#   rake "generate:phlex[Admin::Products::Show]"
#   NOT: rake generate:phlex[Admin::Products::Show]  # This will fail

namespace :generate do
  desc 'Generate a Phlex view file'
  task :phlex, [:view_path, :args] do |_, params|
    view_path = params[:view_path]

    args = params[:args]&.split(/\s+/) || []

    # Extract namespace and view name
    path_parts = view_path.split('::')
    view_name = path_parts.pop
    namespace = path_parts

    # Prepare the file path
    file_path = %w[app views]
    file_path.concat(namespace.map(&:downcase))
    file_path << "#{view_name.downcase}.rb"

    # Create directories if they don't exist
    FileUtils.mkdir_p(File.dirname(file_path.join('/')))

    # Generate the view content
    content = ['# frozen_string_literal: true']

    # Add namespace modules
    namespace.each do |mod|
      content << "module #{mod}"
    end

    # Start the class definition
    content << "  class #{view_name} < Phlex::HTML"

    # Add initialize method if args are present
    if args.any?
      content << "    def initialize(#{args.map { |arg| "#{arg}:" }.join(', ')})"
      args.each do |arg|
        content << "      @#{arg} = #{arg}"
      end
      content << '    end'
    end

    # Add view_template method
    content << '    def view_template'
    content << '    end'

    # Close all blocks
    content << '  end'
    namespace.size.times { content << 'end' }

    # Write the file
    File.write(file_path.join('/'), "#{content.join("\n")}\n")

    puts "Created Phlex view at #{file_path.join('/')}"
  end
end

require 'bundler/setup'
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/*_test.rb']
  t.warning = false
end

task default: :test
