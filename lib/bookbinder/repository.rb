module Repository
  attr_reader :full_name

  def tag_with(tagname)
    @github.create_ref(full_name, "tags/#{tagname}", sha)
  end

  def sha
    @sha || @github.commits(full_name).first.sha
  end

  private

  def validate_authorization(client)
    # octocat raises an exception with invalid credentials,
    # but will return truthy for a NIL access_token!
    raise Octokit::Unauthorized unless ENV['GITHUB_API_TOKEN'] && client.octocat
  rescue Octokit::Unauthorized
    raise 'Github Unauthorized error: set GITHUB_API_TOKEN correctly.'
  end
end