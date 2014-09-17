module Bookbinder
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
      @git_accessor = git_accessor
      store.fetch([section_hash, local_repo_dir]) { acquire(logger, section_hash, local_repo_dir, destination_dir, target_tag, git_accessor) }
    end

    def initialize(logger, repository, subnav_template)
      @logger = logger
      @subnav_template = subnav_template
      @repository = repository
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

    def write_file_modification_dates_to(cache)
      cache.update_from @repository
    end

    private

    def self.acquire(logger, section_hash, local_repo_dir, destination, target_tag, git_accessor)
      repository = section_hash['repository']
      raise "section repository '#{repository}' is not a hash" unless repository.is_a?(Hash)
      raise "section repository '#{repository}' missing name key" unless repository['name']
      logger.log "Gathering #{repository['name'].cyan}"

      repository = build_repository(logger, destination, local_repo_dir, section_hash, target_tag, git_accessor)
      section = new(logger, repository, section_hash['subnav_template'])

      store[[section_hash, local_repo_dir]] = section
    end
    private_class_method :acquire

    def self.build_repository(logger, destination, local_repo_dir, repo_hash, target_tag, git_accessor)
      if local_repo_dir
        Repository.build_from_local(logger, repo_hash, local_repo_dir, destination)
      else
        Repository.build_from_remote(logger, repo_hash, destination, target_tag, git_accessor)
      end
    end
    private_class_method :build_repository
  end
end