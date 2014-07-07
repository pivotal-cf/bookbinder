require 'spec_helper'

describe PdfGenerator do
  let(:logger) { NilLogger.new }
  let(:target_dir) { Dir.mktmpdir }
  let(:header_file) do
    header_file = File.join(target_dir, 'pdf_header.html')
    File.open(header_file, 'w') { |f| f.write('Header!') }
    header_file
  end

  let(:source_page) do
    source_page = File.join(target_dir, 'pdf_source.html')
    File.open(source_page, 'w') { |f| f.write('Hi!') }
    source_page
  end
  let(:generated_pdf) { File.join(target_dir, 'generated.pdf') }


  it 'generates a PDF from the specified pages and header' do
    silence_io_streams do
      PdfGenerator.new(logger).generate [source_page], generated_pdf, header_file
    end
    expect(File.exist? generated_pdf).to be_true
  end

  context 'when generating pages from a live web-server' do
    before do
      stub_request(:get, "http://example.com/").to_return(:status => 200, :body => 'fortune', :headers => {})
    end

    it 'generates a PDF from a live web-page and header' do
      many_pages = 110.times.map { 'http://example.com' }
      silence_io_streams do
        PdfGenerator.new(logger).generate many_pages, generated_pdf, header_file
      end
      expect(File.exist? generated_pdf).to be_true
    end
  end

  it 'raises an exception if the specified source URL does not exist' do
    bad_website = 'http://website.invalid/pdf.html'
    stub_request(:get, bad_website).to_return(:status => 404)
    expect do
      silence_io_streams do
        PdfGenerator.new(logger).generate [bad_website], 'irrelevant.pdf', header_file
      end
    end.to raise_error(/Could not find file #{Regexp.escape(bad_website)}/)
  end

  it 'raises an exception if the specified header file does not exist' do
    expect do
      silence_io_streams do
        PdfGenerator.new(logger).generate [source_page], 'irrelevant.pdf', 'not_there.html'
      end
    end.to raise_error(/Could not find file not_there.html/)
  end

  it 'raises an exception if the tool does not produce a PDF' do
    pdf_destination = '/dev/null/doomed.pdf'

    expect do
      silence_io_streams do
        PdfGenerator.new(logger).generate [source_page], pdf_destination, header_file
      end
    end.to raise_error(/'wkhtmltopdf' appears to have failed/)
  end

  it 'raises an exception when wkhtmltopdf exits non-zero' do
    tmp_dir = Dir.mktmpdir
    pdf_destination = File.join(tmp_dir, 'anything.pdf')

    expect_any_instance_of(Process::Status).to receive(:success?).and_return false

    expect do
      silence_io_streams do
        PdfGenerator.new(logger).generate [source_page], pdf_destination, header_file
      end
    end.to raise_error(/'wkhtmltopdf' appears to have failed/)
  end

  describe '#generate' do
    let(:target) { Tempfile.new('output.pdf').path }

    it 'calls wkhtmltopdf with the --disable-external-links flag' do
      pdf_generator = PdfGenerator.new(logger)
      expect(pdf_generator).to receive(:`).with(/\s+--disable-external-links\s+/) do
        FileUtils.touch(target)
      end
      pdf_generator.generate([source_page], target, header_file)
    end

    xit 'calls wkhtmltopdf with the --toc flag' do
      pdf_generator = PdfGenerator.new(logger)
      expect(pdf_generator).to receive(:`).with(/\s+--toc\s+/) do
        FileUtils.touch(target)
      end
      pdf_generator.generate([source_page], target, header_file)
    end
  end
end
