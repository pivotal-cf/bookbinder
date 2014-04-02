require 'spec_helper'

def write_arbitrary_yaml_to(location)
  File.open(File.join(location, 'yaml_page.yml'), 'w').puts({foo: 'bar'}.to_yaml)
end

describe Spider do
  include_context 'tmp_dirs'

  let(:port) { 4354 }
  let(:other_page) { File.join('spec', 'fixtures', 'page_with_no_links.html') }
  let(:stylesheet) { File.join('spec', 'fixtures', 'stylesheet.css') }
  let(:present_image) { File.join('spec', 'fixtures', '$!.png') }
  let(:public_directory) { File.join(final_app_dir, 'public') }

  around do |spec|
    stub_request(:get, "http://something-nonexistent.com/absent-remote.gif").to_return(:status => 404, :body => "", :headers => {})
    stub_request(:get, "http://something-surely-existenz.com/present-remote.png").to_return(:status => 200, :body => "", :headers => {})

    FileUtils.mkdir_p public_directory
    FileUtils.cp_r 'template_app/.', final_app_dir
    FileUtils.mkdir(File.join public_directory, 'images')
    FileUtils.cp present_image, File.join(public_directory, 'images', 'present-relative.png')
    FileUtils.cp present_image, File.join(public_directory, 'present-absolute.png')
    FileUtils.cp stylesheet, File.join(public_directory, 'stylesheet.css')
    FileUtils.cp portal_page, File.join(public_directory, 'index.html')
    FileUtils.cp other_page, File.join(public_directory, 'other_page.html')
    write_arbitrary_yaml_to(public_directory)
    WebMock.disable_net_connect!(:allow_localhost => true)

    server_director = ServerDirector.new(directory: final_app_dir, port: port)

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
    let(:spider) { Spider.new app_dir: final_app_dir }

    after { WebMock.disable_net_connect! }

    context 'when there are no broken links' do
      let(:portal_page) { File.join('spec', 'fixtures', 'non_broken_index.html') }

      before do
        FileUtils.rm File.join(public_directory, 'stylesheet.css')
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
    let(:spider) { Spider.new app_dir: final_app_dir }
    let(:host) { 'example.com' }
    let(:portal_page) { File.join('spec', 'fixtures', 'non_broken_index.html') }

    it 'generates a sitemap' do
      spider.generate_sitemap host, port

      sitemap = File.read File.join(final_app_dir, 'public', 'sitemap.txt')
      sites = sitemap.split("\n")
      expect(sites).to match_array(["http://#{host}/index.html", "http://#{host}/other_page.html", "http://#{host}/yaml_page.yml"])
    end

    context 'when there are broken links' do
      let(:portal_page) { File.join('spec', 'fixtures', 'broken_index.html') }
      let(:other_page) { File.join('spec', 'fixtures', 'page_with_broken_links.html') }
      let(:broken_links) do
        [
            "/index.html => http://localhost:#{port}/non_existent.yml".blue,
            "/index.html => http://localhost:#{port}/non_existent/index.html".blue,
            "/index.html => http://localhost:#{port}/also_non_existent/index.html".blue,
            '/index.html => #missing-anchor'.yellow,
            '/index.html => #ill-formed.anchor'.yellow,
            '/index.html => #missing'.yellow,
            '/other_page.html => #this-doesnt'.yellow,
            #'/other_page.html => #this-doesnt'.yellow, #Even though this shows up twice, we ignore duplicates
            '/index.html => #missing.and.bad'.yellow,
            '/index.html => #still-bad=anchor'.yellow,
            '/other_page.html => #another"bad"anchor'.yellow,
            'public/stylesheet.css => absent-relative.gif'.blue,
            'public/stylesheet.css => /absent-absolute.gif'.blue,
            'public/stylesheet.css => http://something-nonexistent.com/absent-remote.gif'.blue,
        ]
      end

      it 'names them' do
        announcements = []
        allow(BookbinderLogger).to receive(:log) do |announcement|
          announcements << announcement unless announcement.match(/Vienna|broken links!/)
        end

        spider.generate_sitemap host, port

        expect(announcements).to match_array(broken_links)
      end

      it 'logs a count of them' do
        broken_link_counts = 2.times.map { "\nFound #{broken_links.count} broken links!".red }

        announcements = []
        allow(BookbinderLogger).to receive(:log) do |announcement|
          announcements << announcement if announcement.match(/broken links!/)
        end

        spider.generate_sitemap host, port

        expect(announcements).to match_array(broken_link_counts)
      end
    end
  end
end
