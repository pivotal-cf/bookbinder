class GitClient < Octokit::Client
  class GitClient::TokenException < StandardError;end

  def self.get_instance(*args)
    @@shared_instance ||= new(*args)
  end

  def commits(full_name)
    super
  rescue Octokit::NotFound
    raise_error_with_context
  end

  def create_tag!(full_name, tagname, ref)
    self.create_ref(full_name, "tags/#{tagname}", ref)
  rescue Octokit::Unauthorized, Octokit::NotFound
    raise_error_with_context
  end

  def archive_link(*args)
    super
  rescue Octokit::Unauthorized, Octokit::NotFound
    raise_error_with_context
  end

  private

  def raise_error_with_context
    absent_token_message  = '  Cannot access repository! You must set $GITHUB_API_TOKEN.'
    invalid_token_message = '  Cannot access repository! Does your $GITHUB_API_TOKEN have access to this repository? Does it exist?'

    ENV['GITHUB_API_TOKEN'] ? raise(TokenException.new(invalid_token_message)) : raise(TokenException.new(absent_token_message))
  end
end
