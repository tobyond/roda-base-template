# frozen_string_literal: true

module Views
  module Home
    class Index < Phlex::HTML
      def view_template
        render Components::Layout.new do
          div(class: 'flex flex-col items-center justify-center w-full') do
            h1(class: 'font-bold text-xl') { 'Home' }

            p(class: 'mt-10') do
              a(href: '/logout', class: 'text-indigo-600 underline hover:text-white hover:bg-indigo-600 py-2 px-4 rounded-md') { 'Logout' }
            end
          end
        end
      end
    end
  end
end
