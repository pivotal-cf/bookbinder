require_relative 'git_hub_repository'
require_relative 'directory_helpers'

module Bookbinder
  class Book
    include DirectoryHelperMethods
    attr_reader :sections

    def self.from_remote(logger: nil, full_name: nil, destination_dir: nil, ref: nil, git_accessor: Git)
      book = new(logger: logger, full_name: full_name, target_ref: ref, git_accessor: git_accessor)
      book.copy_from_remote(destination_dir) if destination_dir
      book
    end

    def initialize(logger: nil, full_name: nil, target_ref: nil, github_token: nil, sections: [], git_accessor: Git)
      @sections = sections.map do |section|
        GitHubRepository.new logger: logger, full_name: section['repository']['name']
      end

      @repository = GitHubRepository.new(logger: logger, full_name: full_name, target_ref: target_ref, github_token: github_token)
      @git_accessor = git_accessor
    end

    def full_name
      @repository.full_name
    end

    def head_sha
      @repository.head_sha
    end

    def directory
      @repository.directory
    end

    def get_modification_date_for(file: nil, full_path: nil)
      git_directory, file_relative_path = full_path.split(output_dir_name+'/')
      begin
        git_base_object = Git.open(git_directory)
      rescue => e
        raise "Invalid git repository! #{git_directory} is not a .git directory"
      end
      @repository.get_modification_date_for(file: file_relative_path, git: git_base_object)
    end

    def copy_from_remote(destination_dir)
      @repository.copy_from_remote(destination_dir, @git_accessor)
    end

    def tag_self_and_sections_with(tag)
      (@sections + [@repository]).each { |repo| repo.tag_with tag }
    end
  end
end
