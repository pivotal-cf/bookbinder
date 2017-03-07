require 'middleman-core/renderers/sass'
require 'compass/import-once'

GLOB = /\*|\[.+\]/

# Hack around broken sass globs when combined with import-once
# Targets compass-import-once 1.0.4
# Tracking issue: https://github.com/chriseppstein/compass/issues/1529
module Compass
  module ImportOnce
    module Importer
      def find_relative(uri, base, options, *args)
        if uri =~ GLOB
          force_import = true
        else
          uri, force_import = handle_force_import(uri)
        end
        maybe_replace_with_dummy_engine(super(uri, base, options, *args), options, force_import)
      end

      def find(uri, options, *args)
        if uri =~ GLOB
          force_import = true
        else
          uri, force_import = handle_force_import(uri)
        end
        maybe_replace_with_dummy_engine(super(uri, options, *args), options, force_import)
      end
    end
  end
end

module Middleman
  class CompassExtension < Extension
    # Expose the `compass_config` method inside config.
    expose_to_config :compass_config

    def initialize(app, options_hash={}, &block)
      require 'compass'
      @compass_config_callbacks = []

      super
    end

    def compass_config(&block)
      @compass_config_callbacks << block
    end

    def execute_compass_config_callbacks(config)
      @compass_config_callbacks.each do |b|
        instance_exec(config, &b)
      end
    end

    def after_configuration
      ::Compass.configuration do |compass|
        compass.project_path    = app.config[:source]
        compass.environment     = :development
        compass.cache           = false
        compass.sass_dir        = app.config[:css_dir]
        compass.css_dir         = app.config[:css_dir]
        compass.javascripts_dir = app.config[:js_dir]
        compass.fonts_dir       = app.config[:fonts_dir]
        compass.images_dir      = app.config[:images_dir]
        compass.http_path       = app.config[:http_prefix]

        # Disable this initially, the cache_buster extension will
        # re-enable it if requested.
        compass.asset_cache_buster { |_| nil }

        # Disable this initially, the relative_assets extension will

        compass.relative_assets = false

        # Default output style
        compass.output_style = :nested
      end

      # Call hook
      execute_compass_config_callbacks(::Compass.configuration)

      ::Sass.load_paths.concat(::Compass.configuration.sass_load_paths)
      
      # Tell Tilt to use it as well (for inline sass blocks)
      ::Tilt.register 'sass', CompassSassTemplate
      ::Tilt.prefer(CompassSassTemplate)

      # Tell Tilt to use it as well (for inline scss blocks)
      ::Tilt.register 'scss', CompassScssTemplate
      ::Tilt.prefer(CompassScssTemplate)

      ::Compass::ImportOnce.activate!
    end

    # A Compass Sass template for Tilt, adding our options in
    class CompassSassTemplate < ::Middleman::Renderers::Sass::SassPlusCSSFilenameTemplate
      def sass_options
        super.merge(::Compass.configuration.to_sass_engine_options)
      end
    end

    # A Compass Scss template for Tilt, adding our options in
    class CompassScssTemplate < ::Middleman::Renderers::Sass::ScssPlusCSSFilenameTemplate
      def sass_options
        super.merge(::Compass.configuration.to_sass_engine_options)
      end
    end
  end
end