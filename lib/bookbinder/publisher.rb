require 'middleman-syntax'
require_relative 'deprecated_logger'
require_relative 'directory_helpers'
require_relative 'repositories/section_repository'
require_relative 'server_director'

module Bookbinder
  class Publisher
    include DirectoryHelperMethods

    def initialize(logger, spider, static_site_generator, server_director, file_system_accessor)
      @logger = logger
      @spider = spider
      @static_site_generator = static_site_generator
      @server_director = server_director
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
      result = generate_sitemap(host_for_sitemap, @spider)

      @logger.log "Bookbinder bound your book into #{final_app_dir.to_s.green}"

      !result.has_broken_links?
    end

    private

    attr_reader :section_repository, :logger, :file_system_accessor

    def generate_sitemap(host_for_sitemap, spider)
      raise "Your public host must be a single String." unless host_for_sitemap.is_a?(String)

      @server_director.use_server { |port|
        spider.generate_sitemap host_for_sitemap, port
      }.tap do |sitemap|
        File.write(sitemap.to_path, sitemap.to_xml)
      end
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
