require 'spec_helper'

describe Spider do
  include_context 'tmp_dirs'

  let(:other_page) {File.join('spec', 'fixtures', 'page_with_no_links.html')}

  before do
    public_directory = File.join(final_app_dir, 'public')
    FileUtils.mkdir_p public_directory
    FileUtils.cp_r 'template_app/.', final_app_dir
    FileUtils.cp portal_page, File.join(public_directory, 'index.html')
    FileUtils.cp other_page, File.join(public_directory, 'other_page.html')
    WebMock.disable_net_connect!(:allow_localhost => true)
    spider.generate_sitemap 'example.com'
  end

  describe '#has_broken_links?' do
    let(:output_dir) { tmp_subdir 'output' }
    let(:final_app_dir) { tmp_subdir 'final_app' }
    let(:log_file) { File.join(output_dir, 'wget.log') }
    let(:spider) { Spider.new final_app_dir }
    let(:port) { spider.port }

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
MAP
    end

    context 'when there are broken links' do
      let(:portal_page) { File.join('spec', 'fixtures', 'broken_index.html') }

      it 'announces broken links' do
        BookbinderLogger.should_receive(:log).with(/broken links!/).once

        spider.generate_sitemap host
      end
    end
  end
end
