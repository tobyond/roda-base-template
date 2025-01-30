# frozen_string_literal: true

require_relative 'config/application'
Application.boot

require_relative 'app'
run(Application.development? ? Template.app : Template.freeze.app)
