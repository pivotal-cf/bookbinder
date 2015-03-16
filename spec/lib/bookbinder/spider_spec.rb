require 'yaml'
require_relative '../../../lib/bookbinder/server_director'
require_relative '../../../lib/bookbinder/spider'
require_relative '../../../lib/bookbinder/stabilimentum'
require_relative '../../helpers/nil_logger'
require_relative '../../helpers/tmp_dirs'

module Bookbinder
  describe Spider do
    def write_arbitrary_yaml_to(location)
      File.write(File.join(location, 'yaml_page.yml'), {foo: 'bar'}.to_yaml)
    end

    include_context 'tmp_dirs'

    let(:port) { 4354 }
    let(:stylesheet) { File.join('spec', 'fixtures', 'stylesheet.css') }
    let(:present_image) { File.join('spec', 'fixtures', '$!.png') }
    let(:public_directory) { File.join(final_app_dir, 'public') }
    let(:logger) { NilLogger.new }
    let(:final_app_dir) { tmp_subdir 'final_app' }
    let(:spider) { Spider.new logger, app_dir: final_app_dir }

    around do |spec|
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

      server_director = ServerDirector.new(logger, directory: final_app_dir, port: port)

      server_director.use_server do
        Dir.chdir(final_app_dir) { spec.run }
      end
    end

    context 'when there are no broken links, except for local-page ones' do
      let(:output_dir) { tmp_subdir 'output' }
      let(:log_file) { File.join(output_dir, 'wget.log') }
      let(:logger) { NilLogger.new }
      let(:portal_page) { File.join('spec', 'fixtures', 'non_broken_index.html') }
      let(:other_page) { File.join('spec', 'fixtures', 'page_with_no_links.html') }

      before do
        FileUtils.rm File.join(public_directory, 'stylesheets', 'stylesheet.css')
      end

      it 'creates a valid-looking sitemap' do
        result = spider.generate_sitemap('example.com', port)
        expect(Nokogiri::XML(result.to_xml).css('url loc').first.text).
          to eq('http://example.com/index.html')
      end

      it 'suggests a path for the sitemap, based on the app dir' do
        result = spider.generate_sitemap('example.com', port)
        expect(result.to_path).to eq(Pathname(final_app_dir).join('public/sitemap.xml'))
      end

      it 'reports no broken links' do
        result = spider.generate_sitemap 'example.com', port
        expect(result).not_to have_broken_links
      end
    end

    context 'when there are broken links' do
      let(:host) { 'example.com' }
      let(:sitemap_links) { ["http://#{host}/index.html", "http://#{host}/other_page.html", "http://#{host}/yaml_page.yml"]}
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

      it 'reports that they are present' do
        result = spider.generate_sitemap host, port
        expect(result).to have_broken_links
      end

      it 'logs them' do
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

      it 'excludes them from the sitemap' do
        result = spider.generate_sitemap host, port
        broken_link_targets = broken_links.map {|link| link.split(" => ").last.gsub("localhost:#{port}", host) }
        expect(result.to_xml).not_to include(*broken_link_targets)
      end
    end
  end
end
