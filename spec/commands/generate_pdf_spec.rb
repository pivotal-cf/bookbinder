require 'spec_helper'

describe Cli::GeneratePDF do
  include_context 'tmp_dirs'

  let(:fake_generator) { double(generate: double) }
  let(:sitemap) { File.join('final_app', 'public', 'sitemap.xml') }
  let(:links) { %w(such-uri.html wow-uri.html amaze-uri.html) }
  let(:urls) { %w(http://localhost:41722/such-uri.html http://localhost:41722/wow-uri.html http://localhost:41722/amaze-uri.html) }
  let(:config) { double }
  let(:logger) { NilLogger.new }

  around_with_fixture_repo &:run

  before do
    allow(PdfGenerator).to receive(:new).and_return(fake_generator)
  end

  context 'when a final app has been generated' do

    let(:fake_server_director) { double }

    before do
      `mkdir -p final_app/public`
      allow(ServerDirector).to receive(:new).and_return(fake_server_director)
      SitemapGenerator.new.generate(links, sitemap)
      allow(config).to receive(:has_option?).with('pdf').and_return(true)
      allow(config).to receive(:pdf).and_return({'header' => header_url, 'filename' => target_file})

      allow(fake_server_director).to receive(:use_server) do |&block|
        Dir.chdir('final_app') { block.call 41722 }
      end
    end

    context 'without a pdf_index' do
      let(:target_file) { 'GeneratedPdf.pdf' }
      let(:header_url) { 'header.html' }
      let(:header_full_url) { "http://localhost:41722/#{header_url}" }

      it 'sends all pages in the sitemap to the PdfGenerator' do
        expect(fake_generator).to receive(:generate).with urls, target_file, header_full_url
        Cli::GeneratePDF.new(logger, config).run([])
      end
    end

    context 'when provided with a pdf_index' do
      let(:pdf_index_links) { %w(some-uri.html some-other-uri.html) }
      let(:pdf_index_urls) { %w(http://localhost:41722/some-uri.html http://localhost:41722/some-other-uri.html) }
      let(:header_url) { 'dogs/index.html' }
      let(:header_full_url) { "http://localhost:41722/#{header_url}" }
      let(:target_file) { 'pdf_index.pdf' }

      before do
        File.write('pdf_index.yml', { 'pages' => pdf_index_links}.to_yaml)
      end

      it 'sends all pages in the pdf_index to the PdfGenerator' do
        expect(fake_generator).to receive(:generate).with pdf_index_urls, target_file, header_full_url
        Cli::GeneratePDF.new(logger, config).run(['pdf_index.yml'])
      end
    end
  end

  context 'when a final app has not been generated' do
    it 'raises' do
      expect {
        Cli::GeneratePDF.new(logger, config).run([])
      }.to raise_error(Cli::GeneratePDF::AppNotPublished)
    end
  end
end
