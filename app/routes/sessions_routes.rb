# frozen_string_literal: true

class SessionsRoutes
  MyApp.hash_branch 'sessions' do |r|
    r.is do
      # POST /sessions (create)
      r.post do
        if (user = User.authenticate_by(email: r.params['email'], password: r.params['password']))
          r.start_new_session_for(user)

          r.redirect '/home'
        else
          r.redirect '/login'
        end
      end
    end
  end

  MyApp.hash_branch 'logout' do |r|
    r.get do
      r.require_authentication

      if current_user
        terminate_session
        r.redirect '/login'
      end
    end
  end

  MyApp.hash_branch 'login' do |r|
    r.get do
      r.set_current_user

      if current_user
        r.redirect '/home'
      else
        Sessions::New.new(token: csrf_token('/sessions')).call
      end
    end
  end
end
