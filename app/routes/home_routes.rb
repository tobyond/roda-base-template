# frozen_string_literal: true

class HomeRoutes
  MyApp.hash_branch 'home' do |r|
    r.is do
      r.require_authentication

      Home::Index.call
    end
  end
end
