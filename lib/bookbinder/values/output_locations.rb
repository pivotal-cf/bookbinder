require_relative '../directory_helpers'

module Bookbinder
  class OutputLocations
    attr_reader :final_app_dir, :layout_repo_dir

    include DirectoryHelperMethods

    def initialize(final_app_dir: nil, layout_repo_dir: nil, context_dir: nil, local_repo_dir: nil)
      @final_app_dir = final_app_dir
      @layout_repo_dir = layout_repo_dir
      @context_dir = context_dir
      @local_repo_dir = local_repo_dir
    end

    def output_dir
      context_dir.join(output_dir_name)
    end

    def local_repo_dir
      Pathname(@local_repo_dir) if @local_repo_dir
    end

    def dita_home_dir
      output_dir.join('dita')
    end

    def cloned_dita_dir
      dita_home_dir.join('dita_sections')
    end

    def html_from_dita_dir
      dita_home_dir.join('html_from_dita')
    end

    def formatted_dir
      dita_home_dir.join('site_generator_ready')
    end

    def site_generator_home
      output_dir.join('master_middleman')
    end

    def source_for_site_generator
      site_generator_home.join('source')
    end

    def subnavs_for_layout_dir
      source_for_site_generator.join('subnavs')
    end

    def dita_subnav_template_path
      source_for_site_generator.join('subnavs', '_dita_subnav_template.erb')
    end

    private

    def context_dir
      Pathname(@context_dir)
    end
  end
end
