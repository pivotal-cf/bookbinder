class Publisher

  include ShellOut
  include BookbinderLogger

  def publish(options)
    output_dir = options[:output_dir]
    final_app_dir = options[:final_app_dir]

    prepare_app final_app_dir, output_dir

    output_master_middleman_dir = File.join output_dir, 'master_middleman'
    FileUtils.cp_r options[:master_middleman_dir], output_master_middleman_dir

    options[:repos].each do |repo_hash|
      get_repo options, output_master_middleman_dir, repo_hash
    end

    MiddlemanRunner.new.run final_app_dir, output_master_middleman_dir

    has_no_broken_links = check_broken_links options

    if options[:pdf]
      source_page = File.join(final_app_dir, 'public', options[:pdf][:page])
      generated_pdf_file = File.join(final_app_dir, 'public', options[:pdf][:filename])
      PdfGenerator.new.generate source_page, generated_pdf_file
    end

    log "Bookbinder bound your book into #{options[:final_app_dir].green}"

    has_no_broken_links
  end

  private

  def check_broken_links(options)
    spider = Spider.new options[:output_dir], options[:final_app_dir]
    broken_links = spider.find_broken_links
    if broken_links.size > 0
      log "\nFound #{broken_links.count} broken links!".red
      broken_links.each { |line| log line }
    else
      log "\nNo broken links!".green
    end

    broken_links.size > 0 ? false : true
  end

  def get_repo(options, output_master_middleman_dir, repo_hash)
    doc_repo = DocRepo.new repo_hash,
                           options[:github_username],
                           options[:github_password],
                           options[:local_repo_dir]
    log 'Processing ' + doc_repo.full_name.cyan
    doc_repo.copy_to File.join(output_master_middleman_dir, 'source')
  end

  def prepare_app(final_app_dir, output_dir)
    FileUtils.mkdir_p output_dir
    FileUtils.rm_rf File.join output_dir, '.'
    FileUtils.rm_rf File.join final_app_dir, '.'
    public_dir = File.join(final_app_dir, 'public')
    FileUtils.mkdir_p public_dir

    spec = Gem::Specification.find_by_name("bookbinder")
    gem_root = spec.gem_dir

    FileUtils.cp_r File.join(gem_root, 'template_app/.'), final_app_dir
  end

end