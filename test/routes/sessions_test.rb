require 'test_helper'
require "rack/test"

class SessionsTest < Minitest::Test
  include Rack::Test::Methods

  def app
    MyApp.freeze.app
  end

  def test_login_page_loads
    get "/login"
    assert last_response.ok?
  end

  def test_login_page_redirects_when_logged_in
    user = User.create(
      email: 'test@example.com',
      username: 'testuser',
      password: 'password123'
    )

    login(user.email)

    get "/login"

    assert_equal 302, last_response.status
    assert_equal "/home", last_response.headers["Location"]
  end

  def test_successful_login
    User.create(
      email: 'test@example.com',
      username: 'testuser',
      password: 'password123'
    )

    get "/login"

    assert_equal 0, Session.count

    post "/sessions", {
      email: "test@example.com",
      password: "password123"
    }
    
    assert_equal 302, last_response.status
    assert_equal "/home", last_response.headers["Location"]
    assert_equal 1, Session.count
  end

  def test_failed_session_creation
    User.create(
      email: 'test@example.com',
      username: 'testuser',
      password: 'password123'
    )

    get "/login"

    assert_equal 0, Session.count

    post "/sessions", {
      email: "invalid@example.com",
      password: "wrongpass"
    }
    
    assert_equal 302, last_response.status
    assert_equal "/login", last_response.headers["Location"]
    assert_equal 0, Session.count
  end
end
