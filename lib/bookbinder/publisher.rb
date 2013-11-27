class Publisher

  include ShellOut
  include BookbinderLogger

  def publish(options)
    output_dir = options[:output_dir]
    final_app_dir = options[:final_app_dir]

    prepare_app final_app_dir, output_dir

    output_master_middleman_dir = File.join output_dir, 'master_middleman'
    copy_gem_dir 'master_middleman', output_master_middleman_dir
    FileUtils.cp_r "#{options[:master_middleman_dir]}/.", output_master_middleman_dir

    skip_pdf_generation = options[:pdf].nil?
    options[:repos].each do |repo_hash|
      log 'Processing ' + repo_hash['github_repo'].cyan
      doc_repo = DocRepo.new repo_hash,
                             options[:github_username],
                             options[:github_password],
                             options[:local_repo_dir]
      repo_copied_successfully = doc_repo.copy_to(File.join(output_master_middleman_dir, 'source'))
      requested_pdf_in_this_repo = options[:pdf] && options[:pdf][:page].start_with?(doc_repo.directory)
      if !repo_copied_successfully && requested_pdf_in_this_repo
        skip_pdf_generation = true
        log "  skipping PDF generation because repo #{doc_repo.full_name} was not found".magenta
      end
    end

    MiddlemanRunner.new.run(output_master_middleman_dir, options[:template_variables] || {}, options[:verbose])
    FileUtils.cp_r File.join(output_master_middleman_dir, 'build/.'), File.join(final_app_dir, 'public')

    log_file = File.join(output_dir, 'wget.log')
    has_no_broken_links = check_broken_links log_file, options

    generate_site_map(options[:host_for_sitemap], log_file, final_app_dir)

    unless skip_pdf_generation
      source_page = File.join(final_app_dir, 'public', options[:pdf][:page])
      generated_pdf_file = File.join(final_app_dir, 'public', options[:pdf][:filename])
      header_file = File.join(final_app_dir, 'public', options[:pdf][:header])
      PdfGenerator.new.generate source_page, generated_pdf_file, header_file
    end

    log "Bookbinder bound your book into #{options[:final_app_dir].green}"

    has_no_broken_links
  end

  private

  def check_broken_links(log_file, options)
    spider = Spider.new options[:output_dir], options[:final_app_dir]
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
    File.open( sitemap_file, 'w') do |file|
      file.write(shell_out "grep \\\\.html #{log_file} | grep \"\\-\\-\" | sed s/^.*localhost:4534/http:\\\\/\\\\/#{host}/ | uniq")
    end
  end

  def prepare_app(final_app_dir, output_dir)
    FileUtils.mkdir_p output_dir
    FileUtils.rm_rf File.join output_dir, '.'
    FileUtils.rm_rf File.join final_app_dir, '.'
    public_dir = File.join(final_app_dir, 'public')
    FileUtils.mkdir_p public_dir

    copy_gem_dir 'template_app', final_app_dir
  end

  def copy_gem_dir(dir, output_dir)
    spec = Gem::Specification.find_by_name('bookbinder')
    gem_root = spec.gem_dir
    FileUtils.cp_r File.join(gem_root, "#{dir}/."), output_dir
  end

end