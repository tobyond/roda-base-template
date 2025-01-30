# frozen_string_literal: true

module Views
  module Home
    class Index < Phlex::HTML
      def view_template
        render Components::Layout.new do
          div(class: 'flex items-center justify-center w-full') do
            h1(class: 'font-bold text-xl') { 'Home' }
          end
        end
      end
    end
  end
end
