class Publisher
  def initialize(logger)
    @logger = logger
    @pdf_generator = PdfGenerator.new(@logger)
  end

  def publish(options)
    intermediate_directory = options.fetch(:output_dir)
    final_app_dir = options.fetch(:final_app_dir)
    pdf_requested = options.has_key?(:pdf) && options[:pdf]
    master_middleman_dir = options.fetch(:master_middleman_dir)
    spider = options.fetch(:spider) { Spider.new(@logger, app_dir: final_app_dir) }
    master_dir = File.join intermediate_directory, 'master_middleman'
    workspace_dir = File.join master_dir, 'source'
    build_directory = File.join master_dir, 'build/.'
    public_directory = File.join final_app_dir, 'public'

    prepare_directories final_app_dir, intermediate_directory, workspace_dir, master_middleman_dir, master_dir
    FileUtils.cp 'redirects.rb', final_app_dir if File.exists?('redirects.rb')
    sections = gather_sections(workspace_dir, options)
    generate_site(options, master_dir, sections, build_directory, public_directory)
    generate_peripherals(final_app_dir, options, pdf_requested, sections, spider, @logger)

    @logger.log "Bookbinder bound your book into #{final_app_dir.green}"

    !spider.has_broken_links?
  end

  private

  def generate_peripherals(final_app_dir, options, pdf_requested, repos, spider, logger)
    server_director = ServerDirector.new(logger, directory: final_app_dir)
    server_director.use_server do |port|
      sitemap = spider.generate_sitemap options.fetch(:host_for_sitemap), port

      links_for_pdf = options[:pdf_index] || sitemap

      if pdf_requested
        generate_pdf(final_app_dir, options.fetch(:pdf), port) if repo_with_pdf_page_present?(options, repos)
        generate_docset_pdf(final_app_dir, options.fetch(:pdf), port, links_for_pdf) unless links_for_pdf.empty?
      end
    end
  end

  def generate_site(options, middleman_dir, repos, build_dir, public_dir)
    MiddlemanRunner.new(@logger).run(middleman_dir,
                                     options.fetch(:template_variables, {}),
                                     options[:local_repo_dir],
                                     options[:verbose], repos, options[:host_for_sitemap]
    )
    FileUtils.cp_r build_dir, public_dir
  end

  def repo_with_pdf_page_present?(options, repos)
    pdf_page = options.fetch(:pdf)[:page]
    return false unless pdf_page
    pdf_repo = repos.find { |repo| pdf_page.start_with?(repo.directory) }
    unless pdf_repo
      @logger.warn "No repository directories match the path to specified PDF page: #{pdf_page}"
      return false
    end
    pdf_repo.copied?
  end

  def gather_sections(workspace, options)
    options.fetch(:sections).map do |section|
      Section.get_instance(@logger, section_hash: section, destination_dir: workspace,
                           local_repo_dir: options[:local_repo_dir],
                           target_tag: options[:target_tag]
      )
    end
  end

  def generate_pdf(final_app_dir, options, port)
    source_page = URI::HTTP.build({:host => "localhost", :port => port, :protocol => "http://", :path => '/'+options.fetch(:page)})
    generated_pdf_file = File.join(final_app_dir, 'public', options.fetch(:filename))
    header_file = URI::HTTP.build({:host => "localhost", :port => port, :protocol => "http://", :path => '/'+options.fetch(:header)})
    @pdf_generator.generate [source_page], generated_pdf_file, header_file
  end

  def generate_docset_pdf(final_app_dir, options, port, raw_sources)
    sources = raw_sources.map { |s| s.match(/localhost/) ? URI(s) : URI("http://localhost:#{port}/#{s}") }
    generated_pdf_file = File.join(final_app_dir, 'public', 'FullDocSet.pdf')
    header_file = URI::HTTP.build({:host => "localhost", :port => port, :protocol => "http://", :path => '/'+options.fetch(:header)})
    @pdf_generator.generate sources, generated_pdf_file, header_file
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
