require 'middleman-syntax'
require_relative 'deprecated_logger'
require_relative 'directory_helpers'
require_relative 'repositories/section_repository'

module Bookbinder
  class Publisher
    include DirectoryHelperMethods

    def initialize(logger, sitemap_writer, static_site_generator, file_system_accessor)
      @logger = logger
      @sitemap_writer = sitemap_writer
      @static_site_generator = static_site_generator
      @file_system_accessor = file_system_accessor
    end

    def publish(subnavs, cli_options, output_paths, publish_config)
      intermediate_directory = output_paths.output_dir
      final_app_dir = output_paths.final_app_dir
      master_dir = File.join intermediate_directory, 'master_middleman'
      workspace_dir = File.join master_dir, 'source'
      build_directory = File.join master_dir, 'build/.'
      public_directory = File.join final_app_dir, 'public'

      FileUtils.cp 'redirects.rb', final_app_dir if File.exists?('redirects.rb')

      host_for_sitemap = publish_config.fetch(:host_for_sitemap)

      generate_site(cli_options, output_paths, publish_config, master_dir, workspace_dir, subnavs, build_directory, public_directory)
      result = generate_sitemap(host_for_sitemap)

      @logger.log "Bookbinder bound your book into #{final_app_dir.to_s.green}"

      !result.has_broken_links?
    end

    private

    attr_reader :section_repository, :logger, :file_system_accessor, :sitemap_writer

    def generate_sitemap(host_for_sitemap)
      raise "Your public host must be a single String." unless host_for_sitemap.is_a?(String)
      sitemap_writer.write(host_for_sitemap)
    end

    def generate_site(cli_options, output_paths, publish_config, middleman_dir, workspace_dir, subnavs, build_dir, public_dir)
      @static_site_generator.run(middleman_dir,
                                 workspace_dir,
                                 publish_config.fetch(:template_variables, {}),
                                 output_paths.local_repo_dir,
                                 cli_options[:verbose],
                                 subnavs,
                                 publish_config[:host_for_sitemap],
                                 publish_config[:archive_menu])
      file_system_accessor.copy build_dir, public_dir
    end
  end
end
