require 'yaml'
require_relative '../../lib/bookbinder/commands/generate_pdf'
require_relative '../../lib/bookbinder/sitemap_generator'
require_relative '../helpers/expectations'
require_relative '../helpers/tmp_dirs'
require_relative '../helpers/nil_logger'

module Bookbinder
  describe Commands::GeneratePDF do
    include_context 'tmp_dirs'

    let(:fake_generator) { double(generate: double) }
    let(:links) { %w(such-uri.html wow-uri.html amaze-uri.html) }
    let(:urls) { links.map { |l| l.prepend('http://localhost:41722/') } }
    let(:configuration_fetcher) { double('configuration_fetcher') }
    let(:generate_pdf_object) { Commands::GeneratePDF.new(logger, configuration_fetcher) }
    let(:generate) { generate_pdf_object.run(cli_arguments) }
    let(:logger) { NilLogger.new }
    let(:config) { double(:configurator) }

    before do
      allow(configuration_fetcher).to receive(:fetch_config).and_return(config)
    end

    around_with_fixture_repo &:run

    context 'when a final app has not been generated' do
      let(:cli_arguments) {[]}

      it 'raises' do
        expect { generate }.to raise_error Commands::GeneratePDF::AppNotPublished
      end
    end

    context 'when a final app has been generated' do
      before do
        allow(PdfGenerator).to receive(:new).and_return(fake_generator)
        `mkdir -p final_app/public`
        fake_server_director = double(:i_direct_servers)
        allow(ServerDirector).to receive(:new).and_return(fake_server_director)
        SitemapGenerator.new.generate(links, File.join('final_app', 'public', 'sitemap.xml'))
        allow(fake_server_director).to(receive(:use_server)) { |&block| Dir.chdir('final_app') { block.call 41722 } }
      end

      context 'and no PDF config is specified' do
        let(:cli_arguments) {[]}

        let(:header_file) { 'something-else.html' }
        let(:header_url) { "http://localhost:41722/#{header_file}" }

        before do
          allow(config).to receive(:has_option?).with('pdf').and_return true
          allow(config).to receive(:pdf).and_return({'filename' => 'something', 'header' => header_file})
        end

        it 'sends all pages in the sitemap to the PdfGenerator' do
          expect(fake_generator).to receive(:generate).with urls, anything, anything, anything
          generate
        end

        it 'sends the default pdf_header in config.yml to the PdfGenerator' do
          expect(fake_generator).to receive(:generate).with anything, anything, header_url, anything
          generate
        end

        it 'prints a deprecation warning' do
          expect(logger).to receive(:warn).with(/config\.yml.*deprecated/)
          generate
        end

        context 'and config.yml is missing PDF properties' do
          before do
            allow(config).to receive(:has_option?).with('pdf').and_return false
          end

          it 'raises' do
            expect { generate }.to raise_error(/No PDF options provided in config\.yml/)
          end
        end
      end

      context 'and a PDF config is specified' do
        let(:cli_arguments) {[pdf_config_name]}
        let(:pdf_config_name) { 'Crocodiles.yml' }
        let(:header_file) { 'header.html' }
        let(:header_url) { "http://localhost:41722/#{header_file}" }
        let(:notice) { 'This is a cool bit of text' }
        context "but it doesn't exist" do
          it 'raises an error' do
            expect{ generate }.to raise_error(/#{pdf_config_name}.*does not exist/)
          end
        end

        context 'and the PDF config exists' do
          let(:pdf_options) {{'header' => header_file, 'pages' => links, 'copyright_notice' => notice}}

          before { File.write(pdf_config_name, pdf_options.to_yaml) }

          it 'sends the pages from the specified PDF config to the generator' do
            expect(fake_generator).to receive(:generate).with urls, anything, anything, anything
            generate
          end

          context 'when a wildcard is present' do
            let(:wildcard_pages) { %w(top.html doge/* cate/*) }
            let(:links) { %w(top.html doge/such-uri.html doge/some-dir/wow-uri.html doge/amaze-uri.html not-doge/stuff.html cate/meow.html cate/food.html) }
            let(:correct_links) { %w(top.html doge/such-uri.html doge/some-dir/wow-uri.html doge/amaze-uri.html cate/meow.html cate/food.html) }
            let(:correct_urls) { correct_links.map { |l| l.prepend('http://localhost:41722/') } }
            let(:pdf_options) {{'header' => header_file, 'pages' => wildcard_pages, 'copyright_notice' => notice}}

            it 'detects and attempts to expand the wildcard' do
              expect(generate_pdf_object).to receive(:expand_urls).with wildcard_pages, 'localhost:41722'
              generate
            end

            it 'matches the wildcard to the sitemap' do
              expect(fake_generator).to receive(:generate).with correct_urls, anything, anything, anything
              generate
            end
          end

          it 'sends the header in the specified PDF config to the generator' do
            expect(fake_generator).to receive(:generate).with anything, anything, header_url, anything
            generate
          end

          it 'sends the copyright notice in the specified PDF config to the generator' do
            expect(fake_generator).to receive(:generate).with anything, anything, anything, notice
            generate
          end

          it 'names the target file after the PDF config file' do
            expected_name = pdf_config_name.gsub(/yml/, 'pdf')
            expect(fake_generator).to receive(:generate).with anything, expected_name, anything, anything
            generate
          end

          it 'does not print a deprecation warning' do
            expect(logger).to_not receive(:log).with(/config\.yml.*deprecated/)
            generate
          end

          context 'but it is missing required options' do
            let(:pdf_options) {{'pages' => links}}

            it 'raises an error' do
              expect{ generate }.to raise_error(/#{pdf_config_name}.*is missing required key 'header'/)
            end
          end
        end
      end
    end
  end
end
