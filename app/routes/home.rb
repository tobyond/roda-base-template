# frozen_string_literal: true

class Template
  hash_branch 'home' do |r|
    r.is do
      require_authentication

      Views::Home::Index.call
    end
  end
end
