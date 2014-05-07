module Bookbinder
  class Cli
    class GeneratePDF < BookbinderCommand
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

      def self.usage
        '[PDF config.yml]'
      end

      private

      def capture_pages_into_pdf_at(port)
        local_host = "localhost:#{port}"
        header = pdf_options.fetch('header') { raise IncompletePDFConfig, {file: @pdf_config_file, key: :header} }

        if @pdf_config_file
          output_filename = File.basename(@pdf_config_file).gsub(/yml/, 'pdf')
          urls_to_capture = pdf_options.fetch('pages').map { |l| "http://#{local_host}/#{l}" }
        else
          output_filename = pdf_options.fetch('filename')
          urls_to_capture = sitemap_links(local_host)
        end

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