# frozen_string_literal: true

class HomeRoutes
  MyApp.hash_branch 'home' do |r|
    r.is do
      require_authentication

      Views::Home::Index.call
    end
  end
end
