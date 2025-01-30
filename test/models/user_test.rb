# frozen_string_literal: true

require 'test_helper'

class UserTest < Minitest::Test
  def setup
    User.dataset.delete
  end

  def test_creates_user_with_password
    user = User.create(
      email: 'test@example.com',
      username: 'testuser',
      password: 'password123'
    )

    assert user.password_digest, 'Password digest should be present'
    refute_equal 'password123', user.password_digest, 'Password should be hashed'
  end

  def test_authenticates_with_correct_password
    user = User.create(
      email: 'test@example.com',
      username: 'testuser',
      password: 'password123'
    )

    assert user.authenticate?('password123'), 'Should authenticate with correct password'
  end

  def test_rejects_incorrect_password
    user = User.create(
      email: 'test@example.com',
      username: 'testuser',
      password: 'password123'
    )

    refute user.authenticate?('wrong_password'), 'Should not authenticate with incorrect password'
  end

  def test_rejects_authentication_with_nil_password
    user = User.new(email: 'test@example.com', username: 'testuser')
    user.password_digest = nil

    assert_raises(Sequel::ValidationFailed) do
      user.save
    end
  end

  def test_updates_password
    user = User.create(
      email: 'test@example.com',
      username: 'testuser',
      password: 'password123'
    )

    original_digest = user.password_digest
    user.password = 'new_password'
    user.save

    refute_equal original_digest, user.password_digest, 'Password digest should change'
    assert user.authenticate?('new_password'), 'Should authenticate with new password'
    refute user.authenticate?('password123'), 'Should not authenticate with old password'
  end

  def test_valid_authenticate_by
    @user = User.create(
      email: 'test@example.com',
      username: 'testuser',
      password: 'password123'
    )

    user = User.authenticate_by(
      email: "test@example.com",
      password: "password123"
    )
    assert_equal @user.id, user.id
  end

  def test_invalid_authenticate_by
    @user = User.create(
      email: 'test@example.com',
      username: 'testuser',
      password: 'password123'
    )

    user = User.authenticate_by(
      email: "test@example.com",
      password: "wrong"
    )

    assert_nil user
  end

  def test_returns_nil_with_invalid_email
    @user = User.create(
      email: 'test@example.com',
      username: 'testuser',
      password: 'password123'
    )

    user = User.authenticate_by(
      email: "nonexistent@example.com",
      password: "password123"
    )

    assert_nil user
  end

  def test_is_case_insensitive_for_email
    @user = User.create(
      email: 'test@example.com',
      username: 'testuser',
      password: 'password123'
    )

    user = User.authenticate_by(
      email: "TEST@example.com",
      password: "password123"
    )
    assert_equal @user.id, user.id
  end

  def test_returns_nil_when_password_is_nil
    @user = User.create(
      email: 'test@example.com',
      username: 'testuser',
      password: 'password123'
    )

    user = User.authenticate_by(
      email: "test@example.com",
      password: nil
    )
    assert_nil user
  end

  def test_returns_nil_when_email_is_nil
    @user = User.create(
      email: 'test@example.com',
      username: 'testuser',
      password: 'password123'
    )

    user = User.authenticate_by(
      email: nil,
      password: "password123"
    )
    assert_nil user
  end
end
