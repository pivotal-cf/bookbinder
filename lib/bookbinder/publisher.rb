class Publisher
  include ShellOut

  def initialize(logger)
    @logger = logger
  end

  def publish(options)
    intermediate_directory          = options.fetch(:output_dir)
    final_app_dir                   = options.fetch(:final_app_dir)
    pdf_requested                   = options.has_key?(:pdf) && options[:pdf]
    master_middleman_dir            = options.fetch(:master_middleman_dir)
    spider                          = options.fetch(:spider) { Spider.new(@logger, app_dir: final_app_dir) }
    middleman_dir                   = File.join intermediate_directory, 'master_middleman'
    middleman_source_directory      = File.join middleman_dir, 'source'
    build_directory                 = File.join middleman_dir, 'build/.'
    public_directory                = File.join final_app_dir, 'public'

    prepare_directories final_app_dir, intermediate_directory, middleman_source_directory
    copy_directory_from_gem 'master_middleman', middleman_dir
    FileUtils.cp_r File.join(master_middleman_dir, '.'), middleman_dir

    repos = import_repos(middleman_source_directory, options)

    generate_site(options, middleman_dir, repos)
    FileUtils.cp_r build_directory, public_directory

    server_director = ServerDirector.new(@logger, directory: final_app_dir)
    server_director.use_server do |port|
      links_for_pdf = spider.generate_sitemap options.fetch(:host_for_sitemap), port
      generate_pdf(final_app_dir, options.fetch(:pdf), port) if pdf_requested && repo_with_pdf_page_present?(options, repos)
      generate_docset_pdf(final_app_dir, options.fetch(:pdf), port, links_for_pdf)
    end

    @logger.log "Bookbinder bound your book into #{final_app_dir.green}"

    !spider.has_broken_links?
  end

  private

  def generate_site(options, output_master_middleman_dir, repos)
    MiddlemanRunner.new(@logger).run(output_master_middleman_dir,
                            options.fetch(:template_variables, {}),
                            options[:local_repo_dir],
                            options[:verbose], repos, options[:host_for_sitemap]
    )
  end

  def repo_with_pdf_page_present?(options, repos)
    pdf_page = options.fetch(:pdf).fetch(:page)
    pdf_repo = repos.find { |repo| pdf_page.start_with?(repo.directory) }
    pdf_repo.copied?
  end

  def import_repos(middleman_source_directory, options)
    options.fetch(:sections).map do |section_hash|
      import_repo_to(middleman_source_directory, options, section_hash)
    end
  end

  def import_repo_to(destination, options, section_hash)
    Section.get_instance(@logger,
                         section_hash: section_hash,
                         destination_dir: destination,
                         local_repo_dir: options[:local_repo_dir],
                         target_tag: options[:target_tag])
  end

  def generate_pdf(final_app_dir, options, port)
    source_page = URI::HTTP.build({:host=>"localhost", :port=>port, :protocol=>"http://", :path=>'/'+options.fetch(:page)})
    generated_pdf_file = File.join(final_app_dir, 'public', options.fetch(:filename))
    header_file = URI::HTTP.build({:host=>"localhost", :port=>port, :protocol=>"http://", :path=>'/'+options.fetch(:header)})
    PdfGenerator.new(@logger).generate [source_page], generated_pdf_file, header_file
  end

  def generate_docset_pdf(final_app_dir, options, port, raw_sources)
    sources = raw_sources.map { |s| URI(s) }
    generated_pdf_file = File.join(final_app_dir, 'public', 'FullDocSet.pdf')
    header_file = URI::HTTP.build({:host=>"localhost", :port=>port, :protocol=>"http://", :path=>'/'+options.fetch(:header)})
    PdfGenerator.new(@logger).generate sources, generated_pdf_file, header_file
  end

  def prepare_directories(final_app, output, middleman_source)
    FileUtils.mkdir_p output
    FileUtils.rm_rf File.join output, '.'
    FileUtils.rm_rf File.join final_app, '.'
    FileUtils.mkdir_p File.join final_app, 'public'
    FileUtils.mkdir_p middleman_source

    copy_directory_from_gem 'template_app', final_app
  end

  def copy_directory_from_gem(dir, output_dir)
    FileUtils.cp_r File.join(GEM_ROOT, "#{dir}/."), output_dir
  end
end
