class PdfGenerator
  include ShellOut
  include BookbinderLogger

  class MissingSource < StandardError
    def initialize(required_file)
      super "Could not find file #{required_file}"
    end
  end

  def generate(source, target, header)

    check_file_exists source
    check_file_exists header

    command = <<CMD
wkhtmltopdf \
    --margin-top 26mm \
    --margin-left 0mm \
    --margin-right 0mm \
    --margin-bottom 13mm \
    --header-spacing 10 \
    --footer-spacing 5 \
    --footer-font-size 10 \
    --footer-left "   © Copyright 2013-#{Time.now.year}, Pivotal" \
    --footer-center '[page] of [toPage]' \
    --print-media-type \
    --header-html #{header} \
    #{source} \
    #{target}
CMD
    shell_out command

    raise "'wkhtmltopdf' appears to have failed" unless File.exist?(target)

    log "\nYour PDF file was generated to #{target.green}"

  end

  def check_file_exists(required_file)
    unless File.exist? required_file
      log "\nPDF Generation failed (could not find file)!".red
      raise MissingSource, required_file
    end
  end
end

