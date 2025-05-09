# frozen-string-literal: true

require 'openssl'
require 'securerandom'
require 'uri'
require 'rack/utils'

class Roda
  module RodaPlugins
    module RoutingCsrf
      # Default CSRF option values
      DEFAULTS = {
        :field => '_csrf'.freeze,
        :formaction_field => '_csrfs'.freeze,
        :header => 'X-CSRF-Token'.freeze,
        :key => '_roda_csrf_secret'.freeze,
        :require_request_specific_tokens => true,
        :csrf_failure => :raise,
        :check_header => false,
        :check_request_methods => %w'POST DELETE PATCH PUT'.freeze.each(&:freeze)
      }.freeze

      # Exception class raised when :csrf_failure option is :raise and
      # a valid CSRF token was not provided.
      class InvalidToken < RodaError; end

      def self.load_dependencies(app, opts=OPTS, &_)
        app.plugin :_base64
      end

      def self.configure(app, opts=OPTS, &block)
        options = app.opts[:route_csrf] = (app.opts[:route_csrf] || DEFAULTS).merge(opts)
        if block || opts[:csrf_failure].is_a?(Proc)
          if block && opts[:csrf_failure]
            raise RodaError, "Cannot specify both route_csrf plugin block and :csrf_failure option"
          end
          block ||= opts[:csrf_failure]
          options[:csrf_failure] = :csrf_failure_method
          app.define_roda_method(:_roda_route_csrf_failure, 1, &app.send(:convert_route_block, block))
        end
        options[:env_header] = "HTTP_#{options[:header].to_s.gsub('-', '_').upcase}".freeze
        options.freeze
      end

      module InstanceMethods
        def check_csrf!(opts=OPTS, &block)
          return if ENV['RACK_ENV'] == 'test'

          if msg = csrf_invalid_message(opts)
            if block
              @_request.on(&block)
            end
            
            case failure_action = opts.fetch(:csrf_failure, csrf_options[:csrf_failure])
            when :raise
              raise InvalidToken, msg
            when :empty_403
              @_response.status = 403
              headers = @_response.headers
              headers.clear
              headers[RodaResponseHeaders::CONTENT_TYPE] = 'text/html'
              headers[RodaResponseHeaders::CONTENT_LENGTH] ='0'
              throw :halt, @_response.finish_with_body([])
            when :clear_session
              session.clear
            when :csrf_failure_method
              @_request.on{_roda_route_csrf_failure(@_request)}
            when Proc
              RodaPlugins.warn "Passing a Proc as the :csrf_failure option value to check_csrf! is deprecated"
              @_request.on{instance_exec(@_request, &failure_action)} # Deprecated
            else
              raise RodaError, "Unsupported :csrf_failure option: #{failure_action.inspect}"
            end
          end
        end

        def csrf_field
          csrf_options[:field]
        end

        def csrf_header
          csrf_options[:header]
        end

        def csrf_metatag
          "<meta name=\"#{csrf_field}\" content=\"#{csrf_token}\" \/>"
        end

        def csrf_path(action)
          case action
          when nil, '', /\A[#?]/
            # use current path
            request.path
          when /\A(?:https?:\/)?\//
            # Either full URI or absolute path, extract just the path
            URI.parse(action).path
          else
            # relative path, join to current path
            URI.join(request.url, action).path
          end
        end

        def csrf_formaction_tag(path, *args)
          "<input type=\"hidden\" name=\"#{csrf_options[:formaction_field]}[#{Rack::Utils.escape_html(path)}]\" value=\"#{csrf_token(path, *args)}\" \/>"
        end

        def csrf_tag(*args)
          "<input type=\"hidden\" name=\"#{csrf_field}\" value=\"#{csrf_token(*args)}\" \/>"
        end

        def csrf_token(path=nil, method=('POST' if path))
          token = SecureRandom.random_bytes(31)
          token << csrf_hmac(token, method, path)
          [token].pack("m0")
        end

        def use_request_specific_csrf_tokens?
          csrf_options[:require_request_specific_tokens]
        end

        def valid_csrf?(opts=OPTS)
          csrf_invalid_message(opts).nil?
        end

        private

        def csrf_invalid_message(opts)
          opts = opts.empty? ? csrf_options : csrf_options.merge(opts)
          method = request.request_method

          unless opts[:check_request_methods].include?(method)
            return
          end

          path = @_request.path

          unless encoded_token = opts[:token]
            encoded_token = case opts[:check_header]
            when :only
              env[opts[:env_header]]
            when true
              return (csrf_invalid_message(opts.merge(:check_header=>false)) && csrf_invalid_message(opts.merge(:check_header=>:only)))
            else
              params = @_request.params
              ((formactions = params[opts[:formaction_field]]).is_a?(Hash) && (formactions[path])) || params[opts[:field]]
            end
          end

          unless encoded_token.is_a?(String)
            return "encoded token is not a string"
          end

          if (rack_csrf_key = opts[:upgrade_from_rack_csrf_key]) && (rack_csrf_value = session[rack_csrf_key]) && csrf_compare(rack_csrf_value, encoded_token)
            return
          end

          unless encoded_token.bytesize == 84
            return "encoded token length is not 84"
          end

          begin
            submitted_hmac = Base64_.decode64(encoded_token)
          rescue ArgumentError
            return "encoded token is not valid base64"
          end

          random_data = submitted_hmac.slice!(0...31)

          if csrf_compare(csrf_hmac(random_data, method, path), submitted_hmac)
            return
          end

          if opts[:require_request_specific_tokens]
            "decoded token is not valid for request method and path"
          else
            unless csrf_compare(csrf_hmac(random_data, '', ''), submitted_hmac)
              "decoded token is not valid for either request method and path or for blank method and path"
            end
          end
        end
        
        def csrf_options
          opts[:route_csrf]
        end

        def csrf_compare(s1, s2)
          Rack::Utils.secure_compare(s1, s2)
        end

        def csrf_hmac(random_data, method, path)
          OpenSSL::HMAC.digest(OpenSSL::Digest::SHA256.new, csrf_secret, "#{method.to_s.upcase}#{path}#{random_data}")
        end

        def csrf_secret
          key = session[csrf_options[:key]] ||= SecureRandom.base64(32)
          Base64_.decode64(key)
        end
      end
    end

    register_plugin(:routing_csrf, RoutingCsrf)
  end
end
