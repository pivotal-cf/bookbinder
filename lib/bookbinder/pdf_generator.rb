require 'net/http'

module Bookbinder
  class PdfGenerator
    class MissingSource < StandardError
      def initialize(required_file)
        super "Could not find file #{required_file}"
      end
    end

    def initialize(logger)
      @logger = logger
    end

    def generate(sources, target, header, left_footer=nil)
      sources.each { |s| check_destination_exists s }
      check_destination_exists header

      left_footer ||= "   © Copyright 2013-#{Time.now.year}, Pivotal"

      toc_xslt_path = File.expand_path('../../../toc.xslt', __FILE__)

      command = <<-CMD
      wkhtmltopdf \
      --disable-external-links \
      --disable-javascript \
      --load-error-handling ignore \
      --margin-top 26mm \
      --margin-bottom 13mm \
      --header-spacing 10 \
      --header-html #{header} \
      --footer-spacing 5 \
      --footer-font-size 10 \
      --footer-left '#{left_footer}' \
      --footer-center '[page] of [toPage]' \
      --print-media-type \
      toc --xsl-style-sheet #{toc_xslt_path} \
      #{sources.join(' ')} \
      #{target}
      CMD

      `#{command}`

      raise "'wkhtmltopdf' appears to have failed" unless $?.success? && File.exist?(target)

      @logger.log "\nYour PDF file was generated to #{target.green}"

    end

    def check_file_exists(required_file)
      unless File.exist? required_file
        @logger.error "\nPDF Generation failed (could not find file)!"
        raise MissingSource, required_file
      end
    end

    def check_destination_exists(url)
      uri = URI(url)
      if uri.class == URI::Generic
        check_file_exists url
      elsif uri.class == URI::HTTP
        check_url_exists url
      else
        @logger.error "Malformed destination provided for PDF generation source: #{url}"
      end
    end

    def check_url_exists(url)
      res = Net::HTTP.get_response(URI(url))
      raise MissingSource, url if res.code == '404'
    end
  end
end
