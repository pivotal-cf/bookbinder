module Repository
  attr_reader :full_name

  def tag_with(tagname)
    @github.create_tag! full_name, tagname, sha
  end

  def sha
    @sha || 'master'
  end

  def short_name
    @full_name.split('/')[1]
  end

  def head_sha
    @github.commits(full_name).first.sha
  end

  private

  def archive_link
    @archive_link ||= @github.archive_link full_name, ref: sha
  end

  def tags
    @github.tags @full_name
  end
end