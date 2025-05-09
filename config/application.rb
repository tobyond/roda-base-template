# frozen_string_literal: true

require 'zeitwerk'
require 'logger'
require 'sequel/model'
require_relative 'database'
require_relative '../.env'

class Application
  class << self
    attr_reader :loader, :logger, :env

    def boot(env: ENV['RACK_ENV'] || 'development')
      @env = env
      setup_logger
      setup_zeitwerk
      setup_sequel
      self
    end

    def development?
      env == 'development'
    end

    def test?
      env == 'test'
    end

    def production?
      env == 'production'
    end

    def root
      @root ||= File.expand_path('..', __dir__)
    end

    private

    def setup_logger
      @logger = Logger.new($stdout)
      @logger.level = test? ? Logger::FATAL : Logger::INFO
    end

    def setup_zeitwerk
      @loader = Zeitwerk::Loader.new

      # Get all directories in app/ except routes
      app_dirs = Dir.glob(File.join(root, 'app/*'))
                    .select { |f| File.directory?(f) }
                    .reject { |f| f.end_with?('routes') }

      # Push all directories to Zeitwerk
      app_dirs.each do |dir|
        loader.push_dir(dir)
      end

      if development?
        require 'listen'
        loader.enable_reloading
        loader.logger = logger

        # Get relative paths for Listen
        relative_dirs = app_dirs.map { |dir| Pathname.new(dir).relative_path_from(root).to_s }

        Listen.to(*relative_dirs) do |modified, added, removed|
          loader.reload
          changes_logging(modified, added, removed)
        end.start

        # Routes reloading
        Listen.to('app/routes') do |modified, added, removed|
          Dir['app/routes/**/*.rb'].each do |route_file|
            load route_file
          end
          changes_logging(modified, added, removed)
        end.start
      end

      loader.setup
    end

    def setup_sequel
      Sequel::Model.cache_associations = false if development?
      Sequel::Model.plugin :auto_validations
      Sequel::Model.plugin :timestamps
      Sequel::Model.plugin :subclasses unless ENV['RACK_ENV'] == 'development'
      Sequel::Model.plugin :require_valid_schema
      Sequel::Model.plugin :subclasses unless development?
      Sequel::Model.plugin :dirty

      # Set up DB logging
      DB.loggers << logger unless DB.loggers.any?
    end
  end
end
