# frozen_string_literal: true

require 'semantic_logger'

class SemanticLoggerMiddleware
  def initialize(app)
    @app = app
    @logger = SemanticLogger['Rack']
  end

  def call(env)
    request = Rack::Request.new(env)
    start_time = Time.now

    # Extract parameters from different sources
    params = {}

    # Get query parameters from the URL
    params.merge!(request.GET) if request.GET.any?

    # For POST/PUT requests with form data
    if request.post? || request.put? || request.patch?
      begin
        # Try to get form data
        params.merge!(request.POST) if request.POST.any?

        # For JSON requests, read and parse the body
        if request.content_type&.include?('application/json')
          body = request.body.read
          request.body.rewind # Important: rewind so the app can read it again
          if body && !body.empty?
            json_params = JSON.parse(body)
            params.merge!(json_params) if json_params.is_a?(Hash)
          end
        end
      rescue StandardError => e
        @logger.error("Error parsing request body: #{e.message}")
      end
    end

    # Log the request with all parameters
    @logger.info(
      'Request started',
      method: request.request_method,
      path: request.path,
      params: params,
      content_type: request.content_type
    )

    status, headers, body = @app.call(env)

    duration = ((Time.now - start_time) * 1000).round(2)
    @logger.info(
      'Request completed',
      status: status,
      duration_ms: duration
    )

    [status, headers, body]
  end
end
