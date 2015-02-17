module Bookbinder
  class LocalDitaPreprocessor

    def initialize(dita_converter, dita_formatter, local_file_system_accessor)
      @dita_converter = dita_converter
      @dita_formatter = dita_formatter
      @local_file_system_accessor = local_file_system_accessor
    end

    def preprocess(dita_sections, converted_dita_dir, formatted_dita_dir, workspace_dir)
      dita_converter.convert dita_sections, to: converted_dita_dir

      dita_formatter.format converted_dita_dir, formatted_dita_dir

      local_file_system_accessor.copy_named_directory_with_path('images',
                                                                converted_dita_dir,
                                                                workspace_dir)
      local_file_system_accessor.copy_contents(formatted_dita_dir, workspace_dir)
    end


    private

    attr_reader :dita_converter, :dita_formatter, :local_file_system_accessor

  end
end
