require_relative 'git_hub_repository'
require_relative 'ingest/destination_directory'

module Bookbinder
  class Book
    attr_reader :full_name

    def initialize(logger: nil,
                   full_name: nil,
                   github_token: nil,
                   sections: [])
      @full_name = full_name
      @repository = GitHubRepository.new(logger: logger,
                                         full_name: full_name,
                                         github_token: github_token)
      @section_vcs_repos = sections.map do |section|
        GitHubRepository.new(logger: logger,
                             full_name: section['repository']['name'])
      end
    end

    def directory
      Ingest::DestinationDirectory.new(full_name)
    end

    def tag_self_and_sections_with(tag)
      (@section_vcs_repos + [@repository]).each { |repo| repo.tag_with tag }
    end
  end
end
