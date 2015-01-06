require 'spec_helper'
require_relative '../../../lib/bookbinder/stabilimentum'

module Bookbinder
  describe Spider do

    def write_arbitrary_yaml_to(location)
      File.open(File.join(location, 'yaml_page.yml'), 'w').puts({foo: 'bar'}.to_yaml)
    end

    include_context 'tmp_dirs'

    let(:port) { 4354 }
    let(:other_page) { File.join('spec', 'fixtures', 'page_with_no_links.html') }
    let(:stylesheet) { File.join('spec', 'fixtures', 'stylesheet.css') }
    let(:present_image) { File.join('spec', 'fixtures', '$!.png') }
    let(:public_directory) { File.join(final_app_dir, 'public') }
    let(:logger) { NilLogger.new }

    around do |spec|
      stub_request(:get, "http://something-nonexistent.com/absent-remote.gif").to_return(:status => 404, :body => "", :headers => {})
      stub_request(:get, "http://something-surely-existenz.com/present-remote.png").to_return(:status => 200, :body => "", :headers => {})

      FileUtils.mkdir_p public_directory
      FileUtils.mkdir_p File.join(public_directory, 'stylesheets')
      FileUtils.cp_r 'template_app/.', final_app_dir
      FileUtils.mkdir(File.join public_directory, 'images')
      FileUtils.cp present_image, File.join(public_directory, 'images', 'present-relative.png')
      FileUtils.cp present_image, File.join(public_directory, 'present-absolute.png')
      FileUtils.cp stylesheet, File.join(public_directory, 'stylesheets', 'stylesheet.css')
      FileUtils.cp portal_page, File.join(public_directory, 'index.html')
      FileUtils.cp other_page, File.join(public_directory, 'other_page.html')
      write_arbitrary_yaml_to(public_directory)
      WebMock.disable_net_connect!(:allow_localhost => true)

      server_director = ServerDirector.new(logger, directory: final_app_dir, port: port)

      def server_director.log(message)

      end

      server_director.use_server do
        Dir.chdir(final_app_dir) { spec.run }
      end
    end

    describe '#has_broken_links?' do
      let(:output_dir) { tmp_subdir 'output' }
      let(:final_app_dir) { tmp_subdir 'final_app' }
      let(:log_file) { File.join(output_dir, 'wget.log') }
      let(:logger) { NilLogger.new }
      let(:spider) { Spider.new logger, app_dir: final_app_dir }

      after { WebMock.disable_net_connect! }

      context 'when there are no broken links' do
        let(:portal_page) { File.join('spec', 'fixtures', 'non_broken_index.html') }

        before do
          FileUtils.rm File.join(public_directory, 'stylesheets', 'stylesheet.css')
        end

        it 'returns false' do
          spider.generate_sitemap 'example.com', port
          expect(spider).to_not have_broken_links
        end
      end

      context 'when there are broken links' do
        let(:portal_page) { File.join('spec', 'fixtures', 'broken_index.html') }

        it 'returns true' do
          spider.generate_sitemap 'example.com', port
          expect(spider).to have_broken_links
        end
      end
    end

    describe '#generate_sitemap' do
      let(:final_app_dir) { tmp_subdir 'final_app' }
      let(:intermediate_dir) { File.join('spec', 'fixtures') }
      let(:spider) { Spider.new logger, app_dir: final_app_dir }
      let(:host) { 'example.com' }
      let(:portal_page) { File.join('spec', 'fixtures', 'non_broken_index.html') }
      let(:sitemap_links) { ["http://#{host}/index.html", "http://#{host}/other_page.html", "http://#{host}/yaml_page.yml"]}

      it 'requests sitemap generation' do
        sitemap_generator = SitemapGenerator.new
        sitemap_path = File.join(final_app_dir, 'public', 'sitemap.xml')

        allow(SitemapGenerator).to receive(:new).and_return(sitemap_generator)
        expect(sitemap_generator).to receive(:generate) do |incoming_links, incoming_file|
          expect(incoming_links).to match_array(sitemap_links)
          expect(incoming_file).to eq(sitemap_path)
        end
        spider.generate_sitemap host, port
      end

      it 'returns the working links' do
        expect(spider.generate_sitemap(host, port)).to match_array(["http://localhost:#{port}/index.html",
                                                                    "http://localhost:#{port}/other_page.html",
                                                                    "http://localhost:#{port}/yaml_page.yml"])
      end

      context 'when there are broken links' do
        let(:portal_page) { File.join('spec', 'fixtures', 'broken_index.html') }
        let(:other_page) { File.join('spec', 'fixtures', 'page_with_broken_links.html') }
        let(:broken_links) do
          [
              "/index.html => http://localhost:#{port}/non_existent.yml",
              "/index.html => http://localhost:#{port}/non_existent/index.html",
              "/index.html => http://localhost:#{port}/also_non_existent/index.html",
              'public/stylesheets/stylesheet.css => absent-relative.gif',
              'public/stylesheets/stylesheet.css => /absent-absolute.gif',
              'public/stylesheets/stylesheet.css => http://something-nonexistent.com/absent-remote.gif',
          ]
        end
        let(:broken_anchor_links) do
          [
              '/index.html => #missing-anchor',
              '/index.html => #ill-formed.anchor',
              '/index.html => #missing',
              '/other_page.html => #this-doesnt',
              '/index.html => #missing.and.bad',
              '/index.html => #still-bad=anchor',
              '/other_page.html => #another"bad"anchor',
          ]
        end

        it 'names them' do
          broken_links.each do |l|
            expect(logger).to receive(:notify).with(/#{Regexp.escape(l)}/)
          end

          broken_anchor_links.each do |l|
            expect(logger).to receive(:warn).with(/#{Regexp.escape(l)}/)
          end

          spider.generate_sitemap host, port
        end

        it 'logs a count of them' do
          expect(logger).to receive(:error).with("\nFound #{broken_links.count + broken_anchor_links.count} broken links!").twice

          spider.generate_sitemap host, port
        end

        it 'excludes them from the site map' do
          spider.generate_sitemap host, port

          sitemap = File.readlines File.join(final_app_dir, 'public', 'sitemap.xml')
          broken_link_targets = broken_links.map {|link| link.split(" => ").last.gsub("localhost:#{port}", host) }

          expect(sitemap).not_to include(*broken_link_targets)
        end
      end
    end
  end
end
