# frozen_string_literal: true

class AssetHelper
  class << self
    def manifest
      @manifest ||=
        if File.exist?(manifest_path)
          JSON.parse(File.read(manifest_path))
        else
          {}
        end
    end

    def path_for(name)
      # In production, use the manifest to find fingerprinted path
      if ENV['RACK_ENV'] == 'production' && manifest[name]
        "/#{manifest[name]}"
      else
        # In development, use the regular path
        "/#{name}"
      end
    end

    def javascript_path(name)
      name = "#{name}.js" unless name.end_with?('.js')
      path_for(name)
    end

    def stylesheet_path(name)
      name = "#{name}.css" unless name.end_with?('.css')
      path_for(name)
    end

    def reset_manifest
      @manifest = nil
    end

    private

    def manifest_path
      File.join('public', 'manifest.json')
    end
  end
end
