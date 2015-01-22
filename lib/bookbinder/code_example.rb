require_relative 'section'

module Bookbinder
  class CodeExample < Section

    attr_reader :subnav_template, :destination_dir, :path_to_repository, :full_name, :copied, :directory_name

    def initialize(path_to_repository, full_name, copied, subnav_template, destination_dir, directory_name)
      @subnav_template = subnav_template
      @destination_dir = destination_dir
      @path_to_repository = path_to_repository
      @full_name = full_name
      @copied = copied
      @directory_name = directory_name
    end
  end
end

