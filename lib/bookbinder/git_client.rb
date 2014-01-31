class GitClient < Octokit::Client

  ABSENT_TOKEN_MESSAGE = '  Cannot access repository! You must set $GITHUB_API_TOKEN.'
  INVALID_TOKEN_MESSAGE = '  Cannot access repository! Does your $GITHUB_API_TOKEN have access to this repository? Does it exist?'

  def commits(full_name)
    super
  rescue Octokit::NotFound
    ENV['GITHUB_API_TOKEN'] ? raise(INVALID_TOKEN_MESSAGE) : raise(ABSENT_TOKEN_MESSAGE)
  end

  def create_tag!(full_name, tagname, sha)
    self.create_ref(full_name, "tags/#{tagname}", sha)
  end

  def archive_link(*args)
    super
  rescue Octokit::Unauthorized, Octokit::NotFound
    ENV['GITHUB_API_TOKEN'] ? raise(INVALID_TOKEN_MESSAGE) : raise(ABSENT_TOKEN_MESSAGE)
  end
end