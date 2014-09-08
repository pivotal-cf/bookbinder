require 'ruby-progressbar'
require 'bookbinder/shell_out'

module Bookbinder
  class Repository
    include Bookbinder::ShellOut #keep me

    attr_reader :full_name, :copied_to

    def self.build_from_remote(logger, section_hash, destination_dir, target_ref)
      full_name   = section_hash.fetch('repository', {}).fetch('name')
      target_ref  = target_ref || section_hash.fetch('repository', {})['ref']
      directory   = section_hash['directory']
      repository  = new(logger: logger, full_name: full_name, target_ref: target_ref, github_token: ENV['GITHUB_API_TOKEN'], directory: directory)

      repository.copy_from_remote(destination_dir) if destination_dir

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

    def copy_from_remote(destination_dir)
      output_dir = Dir.mktmpdir
      archive = download_archive
      tarball_path = File.join(output_dir, "#{short_name}.tar.gz")
      File.open(tarball_path, 'wb') { |f| f.write(archive) }

      directory_listing_before = Dir.entries output_dir
      shell_out "tar xzf #{tarball_path} -C #{output_dir}"
      directory_listing_after = Dir.entries output_dir

      from = File.join output_dir, (directory_listing_after - directory_listing_before).first

      repo_directory = File.join(destination_dir, directory)
      FileUtils.mkdir_p repo_directory unless File.exist? repo_directory

      Dir.glob(File.join(from, '*')).each do |file|
        FileUtils.mv file, repo_directory
      end

      @copied_to = repo_directory
    end

    def copy_from_local(destination_dir)
      if File.exist?(path_to_local_repo)
        @logger.log '  copying '.yellow + path_to_local_repo
        destination = File.join(destination_dir, directory)
        FileUtils.mkdir_p(destination)
        FileUtils.cp_r(File.join(path_to_local_repo, '.'), destination)
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

    def download_archive
      @logger.log '  downloading '.yellow + archive_link.blue
      response = Faraday.new.get(archive_link)
      raise "Could not target #{full_name} at ref #{target_ref.magenta}.\nStatus: #{response.status}, #{response.body}" unless response.success?
      response.body
    end

    def shas_by_file
      file_tree = @github.tree(full_name, target_ref, recursive: true)[:tree]
      stripped_file_tree = file_tree.map { |leaf| [leaf[:path], leaf[:sha]] }
      Hash[stripped_file_tree]
    end

    def dates_by_sha(shas_by_file, except: {})
      result = {}

      shas_by_file.each do |file, sha|
        next if except.has_key?(sha)
        result[sha] = @github.last_modified_date_of(full_name, target_ref, file.gsub(/#{Regexp.escape(directory)}\//, ''))
      end

      result
    end

    private

    def target_ref
      @target_ref ||= 'master'
    end

    def path_to_local_repo
      File.join(@local_repo_dir, short_name)
    end

    def archive_link
      @archive_link ||= @github.archive_link full_name, ref: target_ref
    end

    def tags
      @github.tags @full_name
    end
  end
end