# frozen_string_literal: true

module Views
  module Components
    class Layout < Phlex::HTML
      def initialize(title: 'My App', custom_javascript: [])
        @title = title
        @custom_javascript = custom_javascript
      end

      def view_template(&block)
        doctype

        html do
          head do
            title { @title }
            meta(name: 'viewport', content: 'width=device-width,initial-scale=1')

            link href: 'application.css', rel: 'stylesheet'
            script src: 'application.js', type: 'module'

            @custom_javascript.each do |js|
              script src: js, type: 'module'
            end
          end
          body(class: 'h-screen', &block)
        end
      end
    end
  end
end
