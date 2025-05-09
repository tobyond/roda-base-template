# frozen_string_literal: true

module AssetTagHelpers
  def javascript_tag(name, **attributes)
    script(src: AssetHelper.javascript_path(name), **attributes)
  end

  def stylesheet_tag(name, **attributes)
    link(rel: 'stylesheet', href: AssetHelper.stylesheet_path(name), **attributes)
  end
end
