# frozen_string_literal: true

require 'zeitwerk'
require 'logger'
require 'sequel/model'
require_relative 'database'
require_relative '../.env'

# define namespace
module Views; end

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

    private

    def setup_logger
      @logger = Logger.new($stdout)
      @logger.level = test? ? Logger::FATAL : Logger::INFO
    end

    def setup_zeitwerk
      @loader = Zeitwerk::Loader.new

      # Configure paths
      loader.push_dir('app/models')
      loader.push_dir('app/services')
      loader.push_dir('app/views', namespace: Views)

      # Enable reloading in development
      if development?
        loader.enable_reloading
        loader.logger = logger
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
