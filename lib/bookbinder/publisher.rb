class Publisher

  include ShellOut
  include BookbinderLogger

  def publish(options)
    intermediate_directory          = options.fetch(:output_dir)
    final_app_dir                   = options.fetch(:final_app_dir)
    pdf_requested                   = options.has_key?(:pdf) && options[:pdf]
    master_middleman_dir            = options[:master_middleman_dir]
    log_file                        = File.join intermediate_directory, 'wget.log'
    middleman_dir                   = File.join intermediate_directory, 'master_middleman'
    middleman_source_directory      = File.join middleman_dir, 'source'
    build_directory                 = File.join middleman_dir, 'build/.'
    public_directory                = File.join final_app_dir, 'public'

    prepare_directories final_app_dir, intermediate_directory, middleman_source_directory
    copy_directory_from_gem 'master_middleman', middleman_dir
    FileUtils.cp_r File.join(master_middleman_dir, '.'), middleman_dir

    repos = import_repos(middleman_source_directory, options)
    #The lede
    generate_site(options, middleman_dir, repos)
    FileUtils.cp_r build_directory, public_directory

    has_broken_links = has_broken_links? log_file, intermediate_directory, final_app_dir

    #Subledes
    generate_site_map(options.fetch(:host_for_sitemap), log_file, final_app_dir)
    generate_pdf(final_app_dir, options.fetch(:pdf)) if pdf_requested && repo_with_pdf_page_present?(options, repos)

    log "Bookbinder bound your book into #{final_app_dir.green}"

    has_broken_links
  end

  private

  def generate_site(options, output_master_middleman_dir, repos)
    MiddlemanRunner.new.run(output_master_middleman_dir,
                            options.fetch(:template_variables, {}),
                            options[:verbose], repos
    )
  end

  def repo_with_pdf_page_present?(options, repos)
    pdf_page = options.fetch(:pdf).fetch(:page)
    pdf_repo = repos.find { |repo| pdf_page.start_with?(repo.directory) }
    pdf_repo.copied?
  end

  def import_repos(middleman_source_directory, options)
    options.fetch(:repos).map do |repo_hash|
      log 'Processing ' + repo_hash['github_repo'].cyan
      import_repo_to(middleman_source_directory, options, repo_hash)
    end
  end

  def import_repo_to(destination, options, repo_hash)
    shared_arguments = {repo_hash: repo_hash, destination_dir: destination}

    if options.has_key?(:local_repo_dir)
      DocRepo.from_local shared_arguments.merge(local_dir: options.fetch(:local_repo_dir))
    else
      DocRepo.from_remote shared_arguments.merge(target_tag: options[:target_tag])
    end
  end

  def generate_pdf(final_app_dir, options)
    source_page = File.join(final_app_dir, 'public', options.fetch(:page))
    generated_pdf_file = File.join(final_app_dir, 'public', options.fetch(:filename))
    header_file = File.join(final_app_dir, 'public', options.fetch(:header))
    PdfGenerator.new.generate source_page, generated_pdf_file, header_file
  end

  def has_broken_links?(log_file, output_dir, final_app_dir)
    spider = Spider.new output_dir, final_app_dir
    broken_links = spider.find_broken_links log_file

    if broken_links.size > 0
      log "\nFound #{broken_links.count} broken links!".red
      broken_links.each { |line| log line }
    else
      log "\nNo broken links!".green
    end

    broken_links.size > 0 ? false : true
  end

  def generate_site_map(host, log_file, final_app_dir)
    sitemap_file = File.join(final_app_dir, 'public', 'sitemap.txt')
    File.open(sitemap_file, 'w') do |file|
      file.write(shell_out "grep \\\\.html #{log_file} | grep \"\\-\\-\" | sed s/^.*localhost:4534/http:\\\\/\\\\/#{host}/ | uniq")
    end
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