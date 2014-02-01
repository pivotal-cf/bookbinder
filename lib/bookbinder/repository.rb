module Repository
  include BookbinderLogger
  include ShellOut

  attr_reader :full_name

  def tag_with(tagname)
    @github.create_tag! full_name, tagname, target_ref
  end

  def target_ref
    @ref || 'master'
  end

  def short_name
    @full_name.split('/')[1]
  end

  def head_sha
    @github.commits(full_name).first.sha
  end

  def directory
    @directory || short_name
  end

  def copy_from_remote(destination_dir)
    output_dir = Dir.mktmpdir
    log '  downloading '.yellow + archive_link.blue

    archive = download_archive

    tarball_path = File.join(output_dir, "#{short_name}.tar.gz")
    File.open(tarball_path, 'w') { |f| f.write(archive) }

    directory_listing_before = Dir.entries output_dir
    shell_out "tar xzf #{tarball_path} -C #{output_dir}"
    directory_listing_after = Dir.entries output_dir

    from = File.join output_dir, (directory_listing_after - directory_listing_before).first
    FileUtils.mv from, File.join(destination_dir, directory)

    @copied = true
  end

  private

  def download_archive
    response = Faraday.new.get(archive_link)
    raise "Unable to download repository #{@full_name}: server response #{response.status}" unless response.status == 200
    response.body
  end

  def archive_link
    @archive_link ||= @github.archive_link full_name, ref: target_ref
  end

  def tags
    @github.tags @full_name
  end
end