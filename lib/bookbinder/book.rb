class Book
  include Repository
  def self.from_current_repo(constituent_params: {})
    grepped_full_name = `grep url .git/config`.match(/([\w-]+\/[\w-]+)\.git/)[1]
    new full_name: grepped_full_name, constituent_params: constituent_params
  end

  def initialize(full_name: '', constituent_params: [])
    @full_name = full_name

    @constituents = constituent_params.map do |repo_hash|
      DocRepo.from_remote repo_hash: repo_hash
    end

    @github = Octokit::Client.new(access_token: ENV['GITHUB_API_TOKEN'])
    validate_authorization @github
  end

  def tag_constituents_with(tag)
    @constituents.each { |repo| repo.tag_with tag }
  end

  def short_name
    @full_name.split('/')[1]
  end
end