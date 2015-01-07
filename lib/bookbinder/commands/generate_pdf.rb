require_relative '../pdf_generator'
require_relative '../server_director'
require_relative 'bookbinder_command'
require_relative 'naming'

module Bookbinder
  module Commands
    class GeneratePDF < BookbinderCommand
      extend Commands::Naming

      class AppNotPublished < StandardError
        def initialize(msg='You must publish locally before you generate a PDF.')
          super(msg)
        end
      end

      class PDFConfigMissing < StandardError
        def initialize(file)
          super("PDF config file '#{file}' does not exist.")
        end
      end

      class PDFOptionMissing < StandardError
        def initialize(msg='No PDF options provided in config.yml')
          super(msg)
        end
      end

      class IncompletePDFConfig < StandardError
        def initialize(file:nil, key:nil)
          super("#{file} is missing required key '#{key}'")
        end
      end

      def self.usage
        "generate_pdf [<file_name>.yml] \t \t Generate a PDF from the files specified in <file_name.yml>"
      end

      def run(params)
        raise AppNotPublished unless Dir.exists?('final_app')

        @pdf_config_file = find_pdf_config_file(params)

        ServerDirector.new(@logger, directory: 'final_app').use_server { |port| capture_pages_into_pdf_at(port) }
        0
      end

      def find_pdf_config_file(params)
        if params.first
          pdf_config_file = File.expand_path(params.first)
          raise PDFConfigMissing, File.basename(pdf_config_file) unless File.exists?(pdf_config_file)
          pdf_config_file
        else
          @logger.warn "Declaring PDF options in config.yml is deprecated.\nDeclare them in a PDF config file, instead, and target that file when you re-invoke bookbinder.\ne.g. bookbinder generate_pdf theGoodParts.yml"
        end
      end

      private

      def capture_pages_into_pdf_at(port)
        local_host = "localhost:#{port}"
        header = pdf_options.fetch('header') { raise IncompletePDFConfig, {file: @pdf_config_file, key: :header} }

        output_filename = get_output_file_name
        urls_to_capture = get_urls_to_capture(local_host)

        PdfGenerator.new(@logger).generate(urls_to_capture, output_filename, "http://#{local_host}/#{header}", pdf_options['copyright_notice'])
      end

      def pdf_options
        @pdf_options ||= @pdf_config_file ? YAML.load(File.read(@pdf_config_file)) : main_config_pdf_options
      end

      def main_config_pdf_options
        raise PDFOptionMissing unless config.has_option?('pdf')
        {
            'filename' => config.pdf.fetch('filename'),
            'header' => config.pdf.fetch('header')
        }
      end

      def get_output_file_name
        if @pdf_config_file
          File.basename(@pdf_config_file).gsub(/yml/, 'pdf')
        else
          pdf_options.fetch('filename')
        end
      end

      def get_urls_to_capture(local_host)
        if @pdf_config_file
          pages = pdf_options.fetch('pages')
          return expand_urls(pages, local_host) if any_include_wildcard?(pages)
          pages.map { |l| "http://#{local_host}/#{l}" }
        else
          sitemap_links(local_host)
        end
      end

      def any_include_wildcard?(pages)
        pages.each do |page|
          return true if page.include?('*')
        end
        false
      end

      def expand_urls(pages, local_host)
        final_pages = []
        pages.each do |page|
          if page.include?('*')
            matching_pages = find_matching_files_in_directory(page, local_host)
            final_pages += matching_pages
          else
            final_pages << "http://#{local_host}/#{page}"
          end
        end
        final_pages
      end

      def find_matching_files_in_directory(wildcard_page, local_host)
        wildcard_path = wildcard_page.gsub('*','')
        possible_links = sitemap_links(local_host)
        possible_links.select { |link| URI(link).path.match(/^\/#{Regexp.escape(wildcard_path)}/)}
      end

      def sitemap_links(local_host)
        raw_links = Nokogiri::XML(sitemap).css('loc').map &:inner_html
        deployed_host = URI(raw_links[0]).host

        deployed_host ?
            raw_links.map { |l| l.gsub(/#{Regexp.escape(deployed_host)}/, local_host) } :
            raw_links.map { |l| "http://#{local_host}/#{l}" }
      end

      def sitemap
        File.read File.join('public', 'sitemap.xml')
      end
    end
  end
end
