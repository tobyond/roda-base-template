# frozen_string_literal: true

class UsersRoutes
  MyApp.hash_branch 'users' do |r|
    r.is do
      # POST /users (create)
      r.post do
        user = User.create(
          username: r.params['username'],
          email: r.params['email'],
          password: r.params['password']
        )
        start_new_session_for(user)
        r.redirect '/home'
      rescue Sequel::ValidationFailed
        flash[:alert] = 'Error signing up'
        r.redirect '/signup'
      end
    end
  end

  MyApp.hash_branch 'signup' do |r|
    r.get do
      set_current_user

      if current_user
        r.redirect '/home'
      else
        Views::Users::New.new(token: csrf_token('/users')).call
      end
    end
  end
end
