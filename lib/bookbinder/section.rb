require 'bookbinder/directory_helpers'

module Bookbinder
  class SectionRepository
    def initialize(logger,
                   store: nil,
                   section_hash: {},
                   local_repo_dir: nil,
                   destination_dir: Dir.mktmpdir,
                   target_tag: nil,
                   git_accessor: Git)
      @store = store
      @logger = logger
      @section_hash = section_hash
      @local_repo_dir = local_repo_dir
      @destination_dir = destination_dir
      @target_tag = target_tag
      @git_accessor = git_accessor
    end

    def get_instance
      store.fetch([section_hash, local_repo_dir]) {
        acquire(logger, section_hash, local_repo_dir, destination_dir, target_tag, git_accessor)
      }
    end

    private

    attr_reader(:store, :section_hash, :local_repo_dir, :logger,
                :destination_dir, :target_tag, :git_accessor)

    def acquire(logger, section_hash, local_repo_dir, destination_dir, target_tag, git_accessor)
      repository = section_hash['repository']
      raise "section repository '#{repository}' is not a hash" unless repository.is_a?(Hash)
      raise "section repository '#{repository}' missing name key" unless repository['name']
      logger.log "Gathering #{repository['name'].cyan}"
      repository = build_repository(logger, destination_dir, local_repo_dir, section_hash, target_tag, git_accessor)
      section = Section.new(logger, repository, section_hash['subnav_template'], destination_dir)
      store[[section_hash, local_repo_dir]] = section
    end

    def build_repository(logger, destination_dir, local_repo_dir, repo_hash, target_tag, git_accessor)
      if local_repo_dir
        GitHubRepository.build_from_local(logger, repo_hash, local_repo_dir, destination_dir)
      else
        GitHubRepository.build_from_remote(logger, repo_hash, destination_dir, target_tag, git_accessor)
      end
    end
  end

  class Section

    def self.store
      @@store ||= {}
    end

    def self.get_instance(logger,
                          section_hash: {},
                          local_repo_dir: nil,
                          destination_dir: Dir.mktmpdir,
                          target_tag: nil,
                          git_accessor: Git)
      SectionRepository.new(logger,
                            store: store,
                            section_hash: section_hash,
                            local_repo_dir: local_repo_dir,
                            destination_dir: destination_dir,
                            target_tag: target_tag,
                            git_accessor: git_accessor).get_instance
    end

    def initialize(logger, repository, subnav_template, destination_dir)
      @logger = logger
      @subnav_template = subnav_template
      @repository = repository
      @destination_dir = destination_dir
      @git_accessor = Git
    end

    def subnav_template
      @subnav_template.gsub(/^_/, '').gsub(/\.erb$/, '') if @subnav_template
    end

    def directory
      @repository.directory
    end

    def full_name
      @repository.full_name
    end

    def copied?
      @repository.copied?
    end

    def path_to_repository
      File.join @destination_dir, @repository.directory
    end

    def get_modification_date_for(file: nil, full_path: nil)
      unless @repository.has_git_object?
        begin
          git_base_object = @git_accessor.open(@repository.path_to_local_repo)
        rescue => e
          raise "Invalid git repository! Cannot get modification date for section: #{@repository.path_to_local_repo}."
        end
      end
      @repository.get_modification_date_for(file: file, git: git_base_object)
    end
  end
end
