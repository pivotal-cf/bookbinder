module Bookbinder
  class OutputLocations
    attr_reader :final_app_dir, :layout_repo_dir, :output_dir

    def initialize(final_app_dir: nil, layout_repo_dir: nil, output_dir: nil)
      @final_app_dir = final_app_dir
      @layout_repo_dir = layout_repo_dir
      @output_dir = Pathname(output_dir)
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
  end
end
