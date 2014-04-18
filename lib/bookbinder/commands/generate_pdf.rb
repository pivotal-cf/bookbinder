class Cli
  class GeneratePDF < BookbinderCommand

    class AppNotPublished < StandardError;
    end

    def run(params)
      raise Cli::GeneratePDF::AppNotPublished.new('You must publish locally before you generate a PDF.') if !Dir.exists?('final_app')
      raise 'No PDF options provided in config.yml' if pdf_options.nil?


      ServerDirector.new(@logger, directory: 'final_app').use_server do |port|
        local_host = "http://localhost:#{port}/"
        header = pdf_options[:header].prepend(local_host)
        if params.first
          pdf_index_filename = params.first
          pdf_index_urls = pages_in_pdf(port, pdf_index_filename)
          output_filename = pdf_index_filename.gsub(/yml/, 'pdf')
          PdfGenerator.new(@logger).generate(pdf_index_urls, output_filename, header)
        else
          output_filename = 'GeneratedPdf.pdf'
          PdfGenerator.new(@logger).generate sitemap_links(port), output_filename, header
        end
      end
      0
    end

    def self.usage
      '[pdf_index.yml]'
    end

    private

    def pages_in_pdf(port, pdf_index_filename)
      local_host = "http://localhost:#{port}/"
      pdf_index = YAML.load(File.read(File.expand_path(File.join('..', pdf_index_filename))))
      pdf_index.map { |l| l.prepend(local_host) }
    end


    def pdf_options
      return unless config.has_option?('pdf')
      {
          filename: config.pdf.fetch('filename'),
          header: config.pdf.fetch('header')
      }
    end

    def sitemap_links(port)
      raw_links = Nokogiri::XML(sitemap).css('loc').map &:inner_html

      deployed_host = URI(raw_links[0]).host
      local_host = "localhost:#{port}"
      local_host_url = "http://#{local_host}/"

      if deployed_host
        raw_links.map { |l| l.gsub(/#{Regexp.escape(deployed_host)}/, local_host) }
      else
        raw_links.map { |l| l.prepend(local_host_url) }
      end
    end

    def sitemap
      File.read File.join('public', 'sitemap.xml')
    end
  end
end
