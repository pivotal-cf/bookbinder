require_relative 'directory_helpers'
require_relative 'git_hub_repository'

module Bookbinder
  class Section
    def initialize(repository, subnav_template, destination_dir)
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
