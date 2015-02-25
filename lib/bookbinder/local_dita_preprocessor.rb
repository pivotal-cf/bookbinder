module Bookbinder
  class LocalDitaPreprocessor

    def initialize(dita_converter, dita_formatter, local_file_system_accessor)
      @dita_converter = dita_converter
      @dita_formatter = dita_formatter
      @local_file_system_accessor = local_file_system_accessor
    end

    def preprocess(dita_section,
                   html_from_dita_dir,
                   formatted_dita_dir,
                   workspace_dir,
                   subnavs_dir,
                   dita_subnav_template_path)
      dita_converter.convert dita_section, to: html_from_dita_dir

      dita_formatter.format html_from_dita_dir, formatted_dita_dir

      dita_subnav_template_text = local_file_system_accessor.read(dita_subnav_template_path)

      dita_formatter.format_subnav(dita_section,
                                   html_from_dita_dir,
                                   subnavs_dir,
                                   dita_subnav_template_text)

      local_file_system_accessor.copy_named_directory_with_path('images',
                                                                html_from_dita_dir,
                                                                workspace_dir)
      local_file_system_accessor.copy_contents(formatted_dita_dir, workspace_dir)
    end


    private

    attr_reader :dita_converter, :dita_formatter, :local_file_system_accessor

  end
end
