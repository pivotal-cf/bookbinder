class PdfGenerator
  include ShellOut
  include BookbinderLogger

  def generate(source_page, target_pdf_file)
    raise "Could not find file #{source_page}" unless File.exist?(source_page)
    command = <<CMD
wkhtmltopdf \
    --margin-top 0mm \
    --margin-left 0mm \
    --margin-right 0mm \
    --margin-bottom 7mm \
    --footer-font-size 10 \
    --footer-left "   © Copyright 2013, Pivotal" \
    --footer-center '[page] of [toPage]' \
    --print-media-type \
    #{source_page} \
    #{target_pdf_file}
CMD
    shell_out command

    raise "'wkhtmltopdf' appears to have failed" unless File.exist?(target_pdf_file)

    log "\nYour PDF file was generated to #{target_pdf_file.green}"

  end
end
