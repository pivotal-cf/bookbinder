require_relative '../section'

module Bookbinder
  module Repositories
    class SectionRepository
      def initialize(logger,
                     store: nil,
                     git_accessor: Git)
        @store = store
        @logger = logger
        @git_accessor = git_accessor
      end

      def get_instance(attributes,
                       destination_dir: Dir.mktmpdir,
                       local_repo_dir: nil,
                       target_tag: nil)
        store.fetch([attributes, local_repo_dir]) {
          acquire(attributes, local_repo_dir, destination_dir, target_tag)
        }
      end

      private

      attr_reader(:store, :section_hash, :local_repo_dir, :logger,
                  :destination_dir, :target_tag, :git_accessor)

      def acquire(section_hash, local_repo_dir, destination_dir, target_tag)
        repository = section_hash['repository']
        raise "section repository '#{repository}' is not a hash" unless repository.is_a?(Hash)
        raise "section repository '#{repository}' missing name key" unless repository['name']
        logger.log "Gathering #{repository['name'].cyan}"
        repository = build_repository(destination_dir, local_repo_dir, section_hash, target_tag)
        section = Section.new(repository, section_hash['subnav_template'], destination_dir)
        store[[section_hash, local_repo_dir]] = section
      end

      def build_repository(destination_dir, local_repo_dir, repo_hash, target_tag)
        if local_repo_dir
          GitHubRepository.build_from_local(logger, repo_hash, local_repo_dir, destination_dir)
        else
          GitHubRepository.build_from_remote(logger, repo_hash, destination_dir, target_tag, git_accessor)
        end
      end
    end
  end
end
