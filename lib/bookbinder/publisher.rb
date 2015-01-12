require 'middleman-syntax'
require_relative 'bookbinder_logger'
require_relative 'directory_helpers'
require_relative 'section'
require_relative 'server_director'

module Bookbinder
  class Publisher
    include DirectoryHelperMethods

    def initialize(logger, spider, static_site_generator)
      @gem_root = File.expand_path('../../../', __FILE__)
      @logger = logger
      @spider = spider
      @static_site_generator = static_site_generator
    end

    def publish(cli_options, output_paths, publish_config, git_accessor)
      intermediate_directory = output_paths.fetch(:output_dir)
      final_app_dir = output_paths.fetch(:final_app_dir)
      master_middleman_dir = output_paths.fetch(:master_middleman_dir)
      master_dir = File.join intermediate_directory, 'master_middleman'
      workspace_dir = File.join master_dir, 'source'
      build_directory = File.join master_dir, 'build/.'
      public_directory = File.join final_app_dir, 'public'

      @versions = publish_config.fetch(:versions, [])
      @book_repo = publish_config[:book_repo]
      prepare_directories final_app_dir, intermediate_directory, workspace_dir, master_middleman_dir, master_dir, git_accessor
      FileUtils.cp 'redirects.rb', final_app_dir if File.exists?('redirects.rb')

      target_tag = cli_options[:target_tag]
      sections = gather_sections(workspace_dir, publish_config, output_paths, target_tag, git_accessor)
      book = Book.new(logger: @logger,
                      full_name: @book_repo,
                      sections: publish_config.fetch(:sections))
      host_for_sitemap = publish_config.fetch(:host_for_sitemap)

      generate_site(cli_options, output_paths, publish_config, master_dir, book, sections, build_directory, public_directory, git_accessor)
      generate_sitemap(final_app_dir, host_for_sitemap, @spider)

      @logger.log "Bookbinder bound your book into #{final_app_dir.to_s.green}"

      !@spider.has_broken_links?
    end

    private

    def generate_sitemap(final_app_dir, host_for_sitemap, spider)
      server_director = ServerDirector.new(@logger, directory: final_app_dir)
      raise "Your public host must be a single String." unless host_for_sitemap.is_a?(String)

      server_director.use_server { |port| spider.generate_sitemap host_for_sitemap, port }
    end

    def generate_site(cli_options, output_paths, publish_config, middleman_dir, book, sections, build_dir, public_dir, git_accessor)
      @static_site_generator.run(middleman_dir,
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

    def gather_sections(workspace, publish_config, output_paths, target_tag, git_accessor)
      section_data = publish_config.fetch(:sections)
      section_data.map do |attributes|
        section = SectionRepository.new(@logger,
                                        store: Section.store,
                                        section_hash: attributes,
                                        destination_dir: workspace,
                                        local_repo_dir: output_paths[:local_repo_dir],
                                        target_tag: target_tag,
                                        git_accessor: git_accessor).get_instance
        section
      end
    end

    def prepare_directories(final_app, middleman_scratch_space, middleman_source, master_middleman_dir, middleman_dir, git_accessor)
      forget_sections(middleman_scratch_space)
      FileUtils.rm_rf File.join final_app, '.'
      FileUtils.mkdir_p middleman_scratch_space
      FileUtils.mkdir_p File.join final_app, 'public'
      FileUtils.mkdir_p middleman_source

      copy_directory_from_gem 'template_app', final_app
      copy_directory_from_gem 'master_middleman', middleman_dir
      FileUtils.cp_r File.join(master_middleman_dir, '.'), middleman_dir

      copy_version_master_middleman(middleman_source, git_accessor)
    end

    # Copy the index file from each version into the version's directory. Because version
    # subdirectories are sections, this is the only way they get content from their master
    # middleman directory.
    def copy_version_master_middleman(dest_dir, git_accessor)
      @versions.each do |version|
        Dir.mktmpdir(version) do |tmpdir|
          book = Book.from_remote(logger: @logger, full_name: @book_repo,
                                  destination_dir: tmpdir, ref: version, git_accessor: git_accessor)
          index_source_dir = File.join(tmpdir, book.directory, 'master_middleman', source_dir_name)
          index_dest_dir = File.join(dest_dir, version)
          FileUtils.mkdir_p(index_dest_dir)

          Dir.glob(File.join(index_source_dir, 'index.*')) do |f|
            FileUtils.cp(File.expand_path(f), index_dest_dir)
          end
        end
      end
    end

    def forget_sections(middleman_scratch)
      Section.store.clear
      FileUtils.rm_rf File.join middleman_scratch, '.'
    end

    def copy_directory_from_gem(dir, output_dir)
      FileUtils.cp_r File.join(@gem_root, "#{dir}/."), output_dir
    end
  end
end
