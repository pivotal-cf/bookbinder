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

      prepare_directories final_app_dir, intermediate_directory, workspace_dir, master_middleman_dir, master_dir
      FileUtils.cp 'redirects.rb', final_app_dir if File.exists?('redirects.rb')

      file_modification_cache = GitModCache.new File.absolute_path('file_modification_dates')

      sections = gather_sections(workspace_dir, options, file_modification_cache)

      generate_site(options, master_dir, sections, build_directory, public_directory, file_modification_cache)
      generate_sitemap(final_app_dir, options, spider)

      @logger.log "Bookbinder bound your book into #{final_app_dir.green}"

      !spider.has_broken_links?
    end

    private

    def generate_sitemap(final_app_dir, options, spider)
      server_director = ServerDirector.new(@logger, directory: final_app_dir)
      server_director.use_server { |port| spider.generate_sitemap options.fetch(:host_for_sitemap), port }
    end

    def generate_site(options, middleman_dir, sections, build_dir, public_dir, file_modification_cache)
      MiddlemanRunner.new(@logger).run(middleman_dir,
                                       options.fetch(:template_variables, {}),
                                       options[:local_repo_dir], file_modification_cache,
                                       options[:verbose], sections, options[:host_for_sitemap]
      )
      FileUtils.cp_r build_dir, public_dir
    end

    def gather_sections(workspace, options, file_modification_cache)
      options.fetch(:sections).map do |attributes|
        section = Section.get_instance(@logger, section_hash: attributes, destination_dir: workspace,
                                       local_repo_dir: options[:local_repo_dir],
                                       target_tag: options[:target_tag]
        )
        section.write_file_modification_dates_to file_modification_cache
        section
      end
    end

    def prepare_directories(final_app, middleman_scratch_space, middleman_source, master_middleman_dir, middleman_dir)
      forget_sections(middleman_scratch_space)
      FileUtils.rm_rf File.join final_app, '.'
      FileUtils.mkdir_p middleman_scratch_space
      FileUtils.mkdir_p File.join final_app, 'public'
      FileUtils.mkdir_p middleman_source

      copy_directory_from_gem 'template_app', final_app
      copy_directory_from_gem 'master_middleman', middleman_dir
      FileUtils.cp_r File.join(master_middleman_dir, '.'), middleman_dir
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