class Cli
  class GeneratePDF < BookbinderCommand

    class AppNotPublished < StandardError;
    end

    def run(params)
      raise Cli::GeneratePDF::AppNotPublished.new('You must publish locally before you generate a PDF.') if !Dir.exists?('final_app')
      raise 'No PDF options provided in config.yml' if pdf_options.nil?

      ServerDirector.new(@logger, directory: 'final_app').use_server do |port|
        header = "http://localhost:#{port}/" + pdf_options[:header]
        if params.first
          pdf_index_filename = params.first
          target = pdf_index_filename.gsub(/yml/, 'pdf')
          pdf_index = YAML.load(File.read(File.expand_path(File.join('..', pdf_index_filename))))
          pdf_index.each do |pdf_file|
            pdf_file.prepend("http://localhost:#{port}/")
          end
          PdfGenerator.new(@logger).generate(pdf_index, target, header)
        else
          target = File.join('public', 'GeneratedPdf.pdf')
          PdfGenerator.new(@logger).generate sitemap_links(port), target, header
        end
      end
      0
    end

    def self.usage
      '[pdf_index.yml]'
    end

    private

    def pdf_options
      return unless config.has_option?('pdf')
      {
          filename: config.pdf.fetch('filename'),
          header: config.pdf.fetch('header')
      }
    end

    def sitemap_links(port)
      raw_links = Nokogiri::XML(sitemap).css('loc').map &:inner_html
      if URI(raw_links[0]).host
        substitute_hostname("localhost:#{port}", URI(raw_links[0]).host, raw_links)
      else
        raw_links.map { |l| "http://localhost:#{port}/" + l}
      end
    end

    def sitemap
      File.read File.join('public', 'sitemap.xml')
    end

    def substitute_hostname(target_host, temp_host, links)
      links.map { |l| l.gsub(/#{Regexp.escape(temp_host)}/, target_host) }
    end
  end
end
