class PdfGenerator
  include ShellOut
  include BookbinderLogger

  def generate(source_page, target_pdf_file, pdf_header)

    check_file_exists source_page
    check_file_exists pdf_header

    command = <<CMD
wkhtmltopdf \
    --margin-top 26mm \
    --margin-left 0mm \
    --margin-right 0mm \
    --margin-bottom 13mm \
    --header-spacing 10 \
    --footer-spacing 5 \
    --footer-font-size 10 \
    --footer-left "   © Copyright 2013, Pivotal" \
    --footer-center '[page] of [toPage]' \
    --print-media-type \
    --header-html #{pdf_header} \
    #{source_page} \
    #{target_pdf_file}
CMD
    shell_out command

    raise "'wkhtmltopdf' appears to have failed" unless File.exist?(target_pdf_file)

    log "\nYour PDF file was generated to #{target_pdf_file.green}"

  end

  def check_file_exists(required_file)
    unless File.exist? required_file
      log "\nPDF Generation failed (could not find file)!".red
      raise "Could not find file #{required_file}"
    end
  end
end

