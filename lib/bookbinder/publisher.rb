class Publisher

  include ShellOut
  include BookbinderLogger

  def publish(options)
    intermediate_directory = options.fetch(:output_dir)
    final_app_dir = options.fetch(:final_app_dir)
    log_file = File.join(intermediate_directory, 'wget.log')
    pdf_requested = options.has_key?(:pdf) && options[:pdf]
    output_master_middleman_dir = File.join intermediate_directory, 'master_middleman'
    destination_dir = File.join(output_master_middleman_dir, 'source')

    prepare_final_app_directories final_app_dir, intermediate_directory
    copy_directory_from_gem 'master_middleman', output_master_middleman_dir
    FileUtils.cp_r "#{options[:master_middleman_dir]}/.", output_master_middleman_dir
    repos = download_repos(destination_dir, options)

    #The lede
    generate_site(options, output_master_middleman_dir)

    FileUtils.cp_r File.join(output_master_middleman_dir, 'build/.'), File.join(final_app_dir, 'public')
    has_broken_links = has_broken_links? log_file, intermediate_directory, final_app_dir

    #Subledes
    generate_site_map(options.fetch(:host_for_sitemap), log_file, final_app_dir)
    generate_pdf(final_app_dir, options.fetch(:pdf)) if pdf_requested && pdf_page_present?(options, repos)

    log "Bookbinder bound your book into #{options[:final_app_dir].green}"

    has_broken_links
  end

  private

  def generate_site(options, output_master_middleman_dir)
    MiddlemanRunner.new.run(output_master_middleman_dir, options.fetch(:template_variables, {}), options[:verbose])
  end

  def pdf_page_present?(options, repos)
    pdf_page = options.fetch(:pdf).fetch(:page)
    repos.find { |repo| pdf_page.start_with?(repo.directory) }.copied?
  end

  def download_repos(destination_dir, options)
    options.fetch(:repos).map do |repo_hash|
      log 'Processing ' + repo_hash['github_repo'].cyan
      download_repo_to(destination_dir, options, repo_hash)
    end
  end

  def download_repo_to(destination_dir, options, repo_hash)
    shared_arguments = {repo_hash: repo_hash, destination_dir: destination_dir}

    if options.has_key?(:local_repo_dir)
      local_repo_arguments = {local_dir: options.fetch(:local_repo_dir), }
      DocRepo.from_local shared_arguments.merge local_repo_arguments
    else
      remote_repo_arguments = {
          github_username: options.fetch(:github_username),
          github_password: options.fetch(:github_password),
      }
      DocRepo.from_remote shared_arguments.merge remote_repo_arguments
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

  def prepare_final_app_directories(final_app_dir, output_dir)
    FileUtils.mkdir_p output_dir
    FileUtils.rm_rf File.join output_dir, '.'
    FileUtils.rm_rf File.join final_app_dir, '.'
    FileUtils.mkdir_p File.join final_app_dir, 'public'

    copy_directory_from_gem 'template_app', final_app_dir
  end

  def copy_directory_from_gem(dir, output_dir)
    gem_root = Gem::Specification.find_by_name('bookbinder').gem_dir
    FileUtils.cp_r File.join(gem_root, "#{dir}/."), output_dir
  end
end