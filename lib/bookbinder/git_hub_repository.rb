require 'ruby-progressbar'
require 'bookbinder/shell_out'
require 'git'
require_relative 'git_client'
require_relative 'bookbinder_logger'

module Bookbinder
  class GitHubRepository
    class RepositoryCloneError < StandardError
      def initialize(msg=nil)
        super
      end
    end

    include Bookbinder::ShellOut

    attr_reader :full_name, :copied_to

    def self.build_from_remote(logger, section_hash, destination_dir, target_ref, git_accessor)
      full_name = section_hash.fetch('repository', {}).fetch('name')
      target_ref = target_ref || section_hash.fetch('repository', {})['ref']
      directory = section_hash['directory']
      repository = new(logger: logger, full_name: full_name, target_ref: target_ref, github_token: ENV['GITHUB_API_TOKEN'], directory: directory)
      repository.copy_from_remote(destination_dir, git_accessor) if destination_dir
      repository
    end

    def self.build_from_local(logger, section_hash, local_repo_dir, destination_dir)
      full_name = section_hash.fetch('repository').fetch('name')
      directory = section_hash['directory']

      repository = new(logger: logger, full_name: full_name, directory: directory, local_repo_dir: local_repo_dir)
      repository.copy_from_local(destination_dir) if destination_dir

      repository
    end

    def initialize(logger: nil, full_name: nil, target_ref: nil, github_token: nil, directory: nil, local_repo_dir: nil)
      @logger = logger
      #TODO better error message
      raise 'No full_name provided ' unless full_name
      @full_name = full_name
      @github = GitClient.new(logger, access_token: github_token || ENV['GITHUB_API_TOKEN'])
      @target_ref = target_ref
      @directory = directory
      @local_repo_dir = local_repo_dir
    end

    def tag_with(tagname)
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

    def copy_from_remote(destination_dir, git_accessor = Git)
      begin
        @git = git_accessor.clone("git@github.com:#{full_name}", directory, path: destination_dir)
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
      @git.checkout(target_ref) unless target_ref == 'master'
      @copied_to = destination_dir
    end

    def copy_from_local(destination_dir)
      if File.exist?(path_to_local_repo)
        @logger.log '  copying '.yellow + path_to_local_repo
        destination = File.join(destination_dir, directory)

        unless destination.include?(path_to_local_repo)
          FileUtils.mkdir_p(destination)
          FileUtils.cp_r(File.join(path_to_local_repo, '.'), destination)
        end

        @copied_to = File.join(destination_dir, directory)
      else
        announce_skip
      end
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

    def get_modification_date_for(file: nil, git: nil)
      @git ||= git
      raise "Unexpected Error: Git accessor unavailable." if @git.nil?

      irrelevant_path_component = directory+'/'
      repo_path = file.gsub(irrelevant_path_component, '')

      begin
        @git.log(1).object(repo_path).first.date
      rescue Git::GitExecuteError => e
        raise "This file does not exist or is not tracked by git! Cannot get last modified date for #{repo_path}."
      end
    end

    def path_to_local_repo
      File.join(@local_repo_dir, short_name)
    end

    def has_git_object?
      !!@git
    end

    private

    def target_ref
      @target_ref ||= 'master'
    end

    def tags
      @github.tags @full_name
    end
  end
end
