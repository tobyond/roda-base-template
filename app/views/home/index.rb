# frozen_string_literal: true

module Views
  module Users
    class New < Phlex::HTML
      def view_template
        render Components::Layout.new do
          h1 { 'Home' }
        end
      end
    end
  end
end
