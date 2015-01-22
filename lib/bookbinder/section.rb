module Bookbinder
  module SupportedFormats
    HTML = 'html'
    DITA = 'dita'
    Markdown   = 'markdown'
  end

  Section = Struct.new(:content_format, :path_to_repository, :full_name, :copied, :subnav_templ, :destination_dir, :directory_name) do
    def subnav_template
      subnav_templ.sub(/^_/, '').sub(/\.erb$/, '') if subnav_templ
    end

    def directory
      directory_name
    end
  end
end
