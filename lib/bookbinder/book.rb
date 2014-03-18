class Book < Repository
  attr_reader :constituents

  def initialize(full_name: nil, target_ref: nil, github_token: nil, constituent_params: [])
    @constituents = constituent_params.map do |repo_hash|
      Repository.new full_name: repo_hash['github_repo']
    end

    super(full_name: full_name, target_ref: target_ref, github_token: github_token)
  end

  def self.from_remote(full_name: nil, destination_dir: nil, ref: nil)
    repo = self.new(full_name: full_name, target_ref: ref)
    repo.copy_from_remote(destination_dir) if destination_dir
    repo
  end

  def tag_constituents_with(tag)
    @constituents.each { |repo| repo.tag_with tag }
  end
end
