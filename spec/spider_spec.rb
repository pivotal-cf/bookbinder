require 'spec_helper'

def write_arbitrary_yaml_to(location)
  File.open(File.join(location, 'yaml_page.yml'), 'w').puts({foo: 'bar'}.to_yaml)
end

describe Spider do
  include_context 'tmp_dirs'

  let(:other_page) {File.join('spec', 'fixtures', 'page_with_no_links.html')}

  before do
    public_directory = File.join(final_app_dir, 'public')
    FileUtils.mkdir_p public_directory
    FileUtils.cp_r 'template_app/.', final_app_dir
    FileUtils.cp portal_page, File.join(public_directory, 'index.html')
    FileUtils.cp other_page, File.join(public_directory, 'other_page.html')
    write_arbitrary_yaml_to(public_directory)
    WebMock.disable_net_connect!(:allow_localhost => true)
  end

  describe '#has_broken_links?' do
    let(:output_dir) { tmp_subdir 'output' }
    let(:final_app_dir) { tmp_subdir 'final_app' }
    let(:log_file) { File.join(output_dir, 'wget.log') }
    let(:spider) { Spider.new final_app_dir }
    let(:port) { spider.port }

    before { spider.generate_sitemap 'example.com' }

    after { WebMock.disable_net_connect! }

    context 'when there are no broken links' do
      let(:portal_page) { File.join('spec', 'fixtures', 'non_broken_index.html') }

      it 'returns false' do
        spider.should_not have_broken_links
      end
    end

    context 'when there are broken links' do
      let(:portal_page) { File.join('spec', 'fixtures', 'broken_index.html') }

      it 'returns true' do
        spider.should have_broken_links
      end
    end
  end

  describe '#generate_sitemap' do
    let(:final_app_dir) { tmp_subdir 'final_app' }
    let(:intermediate_dir) { File.join('spec', 'fixtures') }
    let(:spider) { Spider.new final_app_dir }
    let(:host) { 'example.com' }
    let(:portal_page) { File.join('spec', 'fixtures', 'non_broken_index.html') }

    it 'generates a sitemap' do
      spider.generate_sitemap host

      sitemap = File.read File.join(final_app_dir, 'public', 'sitemap.txt')
      sitemap.split("\n").should  =~ (<<-MAP).split("\n")
http://#{host}/index.html
http://#{host}/other_page.html
http://#{host}/yaml_page.yml
MAP
    end

    context 'when there are broken links' do
      let(:portal_page) { File.join('spec', 'fixtures', 'broken_index.html') }
      let(:other_page) {File.join('spec', 'fixtures', 'page_with_broken_links.html')}

      it 'counts and names them' do
        broken_links = [
          "\nFound 10 broken links!".red,
          'http://localhost:4534/non_existent.yml',
          'http://localhost:4534/non_existent/index.html',
          'http://localhost:4534/also_non_existent/index.html',
          '#missing-anchor',
          '#ill-formed.anchor',
          '#missing',
          '#this-doesnt',
          '#this-doesnt',
          '#missing.and.bad',
          '#still-bad=anchor'
        ]

        announcements = []
        BookbinderLogger.stub(:log) do |announcement|
          announcements << announcement unless announcement.match(/Sinatra/)
        end

        spider.generate_sitemap host

        announcements.should =~ broken_links
      end
    end
  end
end
