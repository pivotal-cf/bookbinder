require_relative '../directory_helpers'
require_relative '../errors/programmer_mistake'

module Bookbinder
  class OutputLocations
    attr_reader :layout_repo_dir

    include DirectoryHelperMethods

    def initialize(final_app_dir: nil,
                   layout_repo_dir: nil,
                   context_dir: nil,
                   local_repo_dir: nil)
      @final_app_dir = final_app_dir
      @layout_repo_dir = layout_repo_dir
      @context_dir = context_dir
      @local_repo_dir = local_repo_dir
    end

    def final_app_dir
      Pathname(@final_app_dir)
    end

    def public_dir
      final_app_dir.join('public')
    end

    def build_dir
      master_dir.join('build/.')
    end

    def workspace_dir
      master_dir.join('source')
    end

    def master_dir
      output_dir.join('master_middleman')
    end

    def output_dir
      context_dir.join(output_dir_name)
    end

    def local_repo_dir
      Pathname(@local_repo_dir) if @local_repo_dir
    end

    def dita_home_dir
      output_dir.join('preprocessing')
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
      if @context_dir.nil?
        raise Errors::ProgrammerMistake.new("You must provide a context_dir to OutputLocations")
      else
        Pathname(@context_dir)
      end
    end
  end
end
