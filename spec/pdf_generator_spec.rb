require 'spec_helper'

describe PdfGenerator do

  let(:target_dir) { Dir.mktmpdir }
  let(:source_page) do
    source_page = File.join(target_dir, 'pdf_source.html')
    File.open(source_page, 'w') { |f| f.write('Hi!') }
    source_page
  end
  let(:generated_pdf) { File.join(target_dir, 'generated.pdf')}

  it 'generates a PDF from the specified page' do
    PdfGenerator.new.generate source_page, generated_pdf
    expect(File.exist? generated_pdf).to be_true
  end

  it 'raises an exception if the specified page does not exist' do
    expect do
      PdfGenerator.new.generate 'not_there.html', 'irrelevant.pdf'
    end.to raise_error(/Could not find file not_there.html/)
  end

  it 'raises an exception if the tool does not produce a PDF' do
    pdf_generator = PdfGenerator.new
    pdf_generator.stub(:shell_out) {}
    expect do
      pdf_generator.generate source_page, 'wont_get_created.pdf'
    end.to raise_error(/'wkhtmltopdf' appears to have failed/)
  end

end