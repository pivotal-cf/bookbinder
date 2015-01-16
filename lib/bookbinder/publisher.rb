require 'middleman-syntax'
require_relative 'bookbinder_logger'
require_relative 'directory_helpers'
require_relative 'repositories/section_repository'
require_relative 'server_director'

module Bookbinder
  class Publisher
    include DirectoryHelperMethods

    def initialize(logger, spider, static_site_generator, server_director, git_accessor)
      @logger = logger
      @spider = spider
      @static_site_generator = static_site_generator
      @git_accessor = git_accessor
      @server_director = server_director
    end

    def publish(sections, cli_options, output_paths, publish_config)
      intermediate_directory = output_paths.fetch(:output_dir)
      final_app_dir = output_paths.fetch(:final_app_dir)
      master_dir = File.join intermediate_directory, 'master_middleman'
      workspace_dir = File.join master_dir, 'source'
      build_directory = File.join master_dir, 'build/.'
      public_directory = File.join final_app_dir, 'public'

      @book_repo = publish_config[:book_repo]

      FileUtils.cp 'redirects.rb', final_app_dir if File.exists?('redirects.rb')

      book = Book.new(logger: @logger,
                      full_name: @book_repo,
                      sections: publish_config.fetch(:sections))
      host_for_sitemap = publish_config.fetch(:host_for_sitemap)

      generate_site(cli_options, output_paths, publish_config, master_dir, workspace_dir, book, sections, build_directory, public_directory, git_accessor)
      generate_sitemap(host_for_sitemap, @spider)


      @logger.log "Bookbinder bound your book into #{final_app_dir.to_s.green}"

      !@spider.has_broken_links?
    end

    private

    attr_reader :git_accessor, :section_repository, :logger

    def generate_sitemap(host_for_sitemap, spider)
      raise "Your public host must be a single String." unless host_for_sitemap.is_a?(String)

      @server_director.use_server { |port| spider.generate_sitemap host_for_sitemap, port }
    end

    def generate_site(cli_options, output_paths, publish_config, middleman_dir, workspace_dir, book, sections, build_dir, public_dir, git_accessor)
      @static_site_generator.run(middleman_dir,
                                 workspace_dir,
                                 publish_config.fetch(:template_variables, {}),
                                 output_paths[:local_repo_dir],
                                 cli_options[:verbose],
                                 book,
                                 sections,
                                 publish_config[:host_for_sitemap],
                                 publish_config[:archive_menu],
                                 git_accessor
      )
      FileUtils.cp_r build_dir, public_dir
    end
  end
end
