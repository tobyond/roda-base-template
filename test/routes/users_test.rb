# frozen_string_literal: true

require 'test_helper'
require 'rack/test'

class UsersTest < Minitest::Test
  include Rack::Test::Methods

  def app
    MyApp.freeze.app
  end

  def test_signup_page_loads
    get '/signup'
    assert last_response.ok?
  end

  def test_successful_signup
    get '/signup'
    csrf_token = extract_csrf_token(last_response.body)

    assert_equal 0, Session.count
    assert_equal 0, User.count

    post '/users', {
      _csrf: csrf_token,
      username: 'testuser',
      email: 'test@example.com',
      password: 'password123'
    }

    assert_equal 302, last_response.status
    assert_equal '/home', last_response.headers['Location']
    assert_equal 1, Session.count
    assert_equal 1, User.count
  end

  def test_unsuccessful_signup
    User.create(
      email: 'test@example.com',
      username: 'testuser',
      password: 'password123'
    )

    get '/signup'
    csrf_token = extract_csrf_token(last_response.body)

    assert_equal 0, Session.count
    assert_equal 1, User.count

    post '/users', {
      _csrf: csrf_token,
      username: 'testuser',
      email: 'test@example.com',
      password: 'password123'
    }

    # Assert the results
    assert_equal 302, last_response.status
    assert_equal '/signup', last_response.headers['Location']
    assert_equal 0, Session.count
    assert_equal 1, User.count
  end
end
