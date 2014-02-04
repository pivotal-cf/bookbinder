class Book
  include Repository
  attr_reader :constituents

  def initialize(full_name: nil, constituent_params: [], ref: nil)
    @full_name = full_name
    @ref = ref

    @constituents = constituent_params.map do |repo_hash|
      DocRepo.from_remote repo_hash: repo_hash
    end

    @github = GitClient.new(access_token: ENV['GITHUB_API_TOKEN'])
  end

  def tag_constituents_with(tag)
    @constituents.each { |repo| repo.tag_with tag }
  end
end