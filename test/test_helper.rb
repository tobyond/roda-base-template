# frozen_string_literal: true

ENV['MT_NO_PLUGINS'] = '1' # Work around stupid autoloading of plugins
ENV['RACK_ENV'] = 'test'
require_relative '../config/application'
Application.boot

require 'minitest/global_expectations/autorun'
require 'minitest/pride'
require_relative '../app'

module Minitest
  class Test
    def setup
      super
      reset_db
    end

    def teardown
      super
      reset_db
    end

    private

    def reset_db
      DB.tables.each { |table| DB[table].truncate(cascade: true) }
    end
  end
end

def extract_csrf_token(response_body)
  response_body.match(/name="_csrf" value="([^"]+)"/)[1]
end

def login(email, password = 'password123')
  get '/login'
  csrf_token = extract_csrf_token(last_response.body)
  post '/sessions', { _csrf: csrf_token, email:, password: }
  assert_equal 302, last_response.status
end
