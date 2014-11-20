require 'bookbinder/directory_helpers'

module Bookbinder
  class Publisher
    def initialize(logger)
      @logger = logger
      @pdf_generator = PdfGenerator.new(@logger)
    end

    def publish(options)
      intermediate_directory = options.fetch(:output_dir)
      final_app_dir = options.fetch(:final_app_dir)
      master_middleman_dir = options.fetch(:master_middleman_dir)
      spider = options.fetch(:spider) { Spider.new(@logger, app_dir: final_app_dir) }
      master_dir = File.join intermediate_directory, 'master_middleman'
      workspace_dir = File.join master_dir, 'source'
      build_directory = File.join master_dir, 'build/.'
      public_directory = File.join final_app_dir, 'public'
      git_accessor = options.fetch(:git_accessor, Git)

      @versions = options.fetch(:versions, [])
      @book_repo = options[:book_repo]
      prepare_directories final_app_dir, intermediate_directory, workspace_dir, master_middleman_dir, master_dir, git_accessor
      FileUtils.cp 'redirects.rb', final_app_dir if File.exists?('redirects.rb')

      sections = gather_sections(workspace_dir, options)
      book = Book.new(logger: @logger,
                      full_name: @book_repo,
                      sections: options.fetch(:sections))

      generate_site(options, master_dir, book, sections, build_directory, public_directory, git_accessor)
      generate_sitemap(final_app_dir, options, spider)

      @logger.log "Bookbinder bound your book into #{final_app_dir.green}"

      !spider.has_broken_links?
    end

    private

    def generate_sitemap(final_app_dir, options, spider)
      server_director = ServerDirector.new(@logger, directory: final_app_dir)
      sitemap_hostname = options.fetch(:host_for_sitemap)
      raise "Your public host must be a single String." unless sitemap_hostname.is_a?(String)

      server_director.use_server { |port| spider.generate_sitemap sitemap_hostname, port }
    end

    def generate_site(options, middleman_dir, book, sections, build_dir, public_dir, git_accessor)
      MiddlemanRunner.new(@logger).run(middleman_dir,
                                       options.fetch(:template_variables, {}),
                                       options[:local_repo_dir], options[:verbose],
                                       book, sections, options[:host_for_sitemap],
                                       git_accessor,
      )
      FileUtils.cp_r build_dir, public_dir
    end

    def gather_sections(workspace, options)

      section_data = options.fetch(:sections)
      section_data.map do |attributes|
        section = Section.get_instance(@logger, section_hash: attributes, destination_dir: workspace,
                                       local_repo_dir: options[:local_repo_dir],
                                       target_tag: options[:target_tag],
                                       git_accessor: options.fetch(:git_accessor, Git)
        )
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
      FileUtils.cp_r File.join(GEM_ROOT, "#{dir}/."), output_dir
    end
  end
end