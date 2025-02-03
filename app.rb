# frozen_string_literal: true

require 'roda'
require 'phlex'

Dir["plugins/**/*.rb"].each do |plugin_file|
  require_relative plugin_file
end

class MyApp < Roda
  opts[:check_dynamic_arity] = false
  opts[:check_arity] = :warn

  plugin :default_headers,
    'Content-Type'=>'text/html',
    #'Strict-Transport-Security'=>'max-age=63072000; includeSubDomains', # Uncomment if only allowing https:// access
    'X-Frame-Options'=>'deny',
    'X-Content-Type-Options'=>'nosniff'

  plugin :content_security_policy do |csp|
    csp.default_src :none
    csp.style_src :self, :unsafe_inline
    csp.form_action :self
    csp.script_src :self
    csp.connect_src :self
    csp.base_uri :none
    csp.frame_ancestors :none
  end

  plugin :route_csrf
  plugin :flash
  plugin :public
  plugin :Integer_matcher_max
  plugin :typecast_params_sized_integers, :sizes=>[64], :default_size=>64

  logger = if ENV['RACK_ENV'] == 'test'
    Class.new{def write(_) end}.new
  else
    $stderr
  end
  plugin :common_logger, logger

  plugin :sessions,
    key: '_MyApp.session',
    secret: ENV.send((ENV['RACK_ENV'] == 'development' ? :[] : :delete), 'SESSION_SECRET')

  plugin :authentication
  plugin :hash_branches

  Dir['app/routes/**/*.rb'].sort.each do |route_file|
    require_relative route_file
  end

  route do |r|
    r.public
    check_csrf!

    r.hash_branches

    r.root do
      Views::Sessions::New.new(token: csrf_token('/sessions')).call
    end
  end
end
