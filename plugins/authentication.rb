# frozen_string_literal: true

class Roda
  module RodaPlugins
    module Authentication
      module InstanceMethods
        def current_user
          request.current_user # Make current_user accessible globally in routes
        end

        def current_session
          request.current_session # Make current_session accessible globally in routes
        end
      end

      module RequestMethods
        attr_reader :current_session, :current_user

        def authenticated?
          current_session
        end

        def require_authentication
          session_result = resume_session
          request_authentication unless session_result
          session_result
        end

        def resume_session
          if (session = find_session_by_cookie)
            set_current_session(session)
          end
        end
        alias set_current_user resume_session

        def find_session_by_cookie
          if (token = session['session_token'])
            Session.where(token: token).first
          end
        end

        def request_authentication
          session[:return_to_after_authenticating] = url
          response.redirect('/login')
          halt
        end

        def after_authentication_url
          session.delete(:return_to_after_authenticating) || '/'
        end

        def start_new_session_for(user)
          @current_user = user
          new_session = Session.create(
            user_id: user.id,
            user_agent: user_agent,
            ip_address: ip
          )
          set_current_session(new_session)
        end

        def set_current_session(session_record) # rubocop:disable Naming/AccessorMethodName
          @current_session = session_record
          @current_user = User[session_record.user_id]
          session['session_token'] = session_record.token
        end

        def terminate_session
          Session.where(token: session['session_token']).delete
          session.delete('session_token')
        end
      end

      def self.configure(app, opts = {})
        app.opts[:authentication] = opts
      end
    end

    register_plugin :authentication, Authentication
  end
end
