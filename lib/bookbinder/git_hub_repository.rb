require 'git'
require_relative 'deprecated_logger'
require_relative 'git_client'
require_relative 'shell_out'

module Bookbinder
  class GitHubRepository
    RepositoryCloneError = Class.new(StandardError)

    include Bookbinder::ShellOut

    attr_reader :full_name, :copied_to

    def self.build_from_remote(logger,
                               section_hash,
                               git_accessor)
      full_name = section_hash.fetch('repository', {}).fetch('name')
      directory = section_hash['directory']
      new(logger: logger,
          full_name: full_name,
          github_token: ENV['GITHUB_API_TOKEN'],
          directory: directory,
          git_accessor: git_accessor)
    end

    def initialize(logger: nil,
                   full_name: nil,
                   github_token: nil,
                   directory: nil,
                   local_repo_dir: nil,
                   git_accessor: nil)
      @logger = logger
      raise 'No full_name provided ' unless full_name
      @full_name = full_name
      @directory = directory
      @local_repo_dir = local_repo_dir

      @github = GitClient.new(access_token: github_token || ENV['GITHUB_API_TOKEN'])
      @git_accessor = git_accessor or raise ArgumentError.new("Must provide a git accessor")
    end

    def tag_with(tagname)
      @logger.log 'Tagging ' + full_name.cyan
      @github.create_tag! full_name, tagname, head_sha
    end

    def short_name
      full_name.split('/')[1]
    end

    def head_sha
      @head_sha ||= @github.head_sha(full_name)
    end

    def directory
      @directory || short_name
    end

    def copy_from_remote(destination_dir, target_ref)
      begin
        @git_base_object = git_accessor.clone("git@github.com:#{full_name}",
                                              directory,
                                              path: destination_dir)
      rescue => e
        if e.message.include? "Permission denied (publickey)"
          raise RepositoryCloneError.new "Unable to access repository #{full_name}. You do not have the correct access rights. Please either add the key to your SSH agent, or set the GIT_SSH environment variable to override default SSH key usage. For more information run: `man git`."
        elsif
          e.message.include? "Repository not found."
          raise RepositoryCloneError.new "Could not read from repository. Please make sure you have the correct access rights and the repository #{full_name} exists."
        else
          raise e
        end
      end
      @git_base_object.checkout(target_ref) unless target_ref == 'master'
      @copied_to = File.join(destination_dir, directory)
    end

    def copied?
      !@copied_to.nil?
    end

    def has_tag?(tagname)
      tags.any? { |tag| tag.name == tagname }
    end

    def update_local_copy
      if File.exist?(path_to_local_repo)
        @logger.log 'Updating ' + path_to_local_repo.cyan
        Kernel.system("cd #{path_to_local_repo} && git pull")
      else
        announce_skip
      end
    end

    def announce_skip
      @logger.log '  skipping (not found) '.magenta + path_to_local_repo
    end

    private

    attr_reader :git_accessor

    def path_to_local_repo
      if @local_repo_dir
        File.join(@local_repo_dir, short_name)
      end
    end

    def tags
      @github.tags @full_name
    end
  end
end
