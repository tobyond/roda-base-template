# frozen_string_literal: true

module Components
  class Layout < Phlex::HTML
    include AssetTagHelpers

    def initialize(title: 'MyApp', custom_javascript: [], csrf_token: nil, body_classes: [])
      @title = title
      @custom_javascript = custom_javascript
      @csrf_token = csrf_token
      @body_classes = body_classes.push(%w[h-[100svh] min-h-[100dvh]]).join(' ')
    end

    def view_template(&block)
      doctype

      html do
        head do
          title { @title }
          meta(name: 'viewport', content: 'width=device-width,initial-scale=1.0,height=device-height,user-scalable=no,maximum-scale=1')
          meta(name: 'csrf-token', content: @csrf_token)

          stylesheet_tag 'application'
          javascript_tag 'application', type: 'module'

          # favicon stub
          link(rel: 'icon', href: 'data:,')

          @custom_javascript.each do |js|
            javascript_tag js
          end
        end

        body(class: @body_classes, &block)
      end
    end
  end
end
