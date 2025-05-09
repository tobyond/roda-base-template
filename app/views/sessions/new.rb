# frozen_string_literal: true

module Sessions
  class New < Phlex::HTML
    def initialize(token: 'woo')
      @token = token
    end

    def view_template
      render Components::Layout.new do
        div(class: 'flex min-h-full flex-col justify-start px-2 py-2 lg:py-12 lg:px-8 bg-gray-50') do
          div(class: 'p-4 sm:mx-auto sm:w-full sm:max-w-sm bg-white border') do
            div(class: 'mt-10 text-center text-2xl/9 font-bold tracking-tight text-gray-900') do
              div(class: 'flex items-center justify-center') { 'Login' }
            end
            div(class: 'mt-10 sm:mx-auto sm:w-full sm:max-w-sm') do
              form(class: 'space-y-6', action: '/sessions', accept_charset: 'UTF-8', method: 'post') do
                input(type: 'hidden', name: '_csrf', value: @token)
                div do
                  label(for: 'email', class: 'block text-sm/6 font-medium text-gray-900') { 'Email' }
                  div(class: 'mt-2') do
                    input(
                      type: 'email',
                      name: 'email',
                      id: 'email',
                      required: true,
                      class:
                      'block w-full rounded-md bg-white px-3 py-1.5 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-gray-300 placeholder:text-gray-400 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-indigo-600 sm:text-sm/6'
                    )
                  end
                end
                div do
                  div(class: 'flex items-center justify-between') do
                    label(for: 'password', class: 'block text-sm/6 font-medium text-gray-900') { 'Password' }
                  end
                  div(class: 'mt-2') do
                    input(
                      type: 'password',
                      name: 'password',
                      id: 'password',
                      autocomplete: 'current-password',
                      required: true,
                      class:
                      'block w-full rounded-md bg-white px-3 py-1.5 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-gray-300 placeholder:text-gray-400 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-indigo-600 sm:text-sm/6'
                    )
                  end
                end
                div do
                  button(
                    type: 'submit',
                    class:
                    'border-indigo-600 border flex w-full justify-center rounded-md bg-indigo-600 px-3 py-1.5 text-sm/6 font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600'
                  ) { 'Sign in' }
                end
              end
              p(class: 'mt-10 text-center text-sm/6 text-gray-500') do
                plain ' Not a member? '
                a(href: '/signup', class: 'font-semibold text-indigo-600 hover:text-indigo-500') { 'Sign up' }
              end
            end
          end
        end
      end
    end
  end
end
