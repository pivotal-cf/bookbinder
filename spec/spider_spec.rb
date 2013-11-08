require 'spec_helper'

describe Spider do

  include_context 'tmp_dirs'

  describe '#find_broken_links' do

    let(:output_dir) { tmp_subdir 'output' }
    let(:final_app_dir) { tmp_subdir 'final_app' }

    let(:spider) do
      public_directory = File.join(final_app_dir, 'public')
      FileUtils.mkdir_p public_directory
      FileUtils.cp_r 'template_app/.', final_app_dir
      FileUtils.cp portal_page, File.join(public_directory, 'index.html')
      spider = Spider.new output_dir, final_app_dir
    end

    context 'when there are broken links' do
      let(:portal_page) { File.join('spec', 'fixtures', 'broken_index.html') }

      it 'finds all broken links and returns them as a list' do
        broken_links = spider.find_broken_links
        broken_links.should =~ ['/non_existent/index.html', '/also_non_existent/index.html']
      end
    end

    context 'there are no broken links' do
      let(:portal_page) { File.join('spec', 'fixtures', 'non_broken_index.html')}
      it 'returns an empty array' do
        broken_links = spider.find_broken_links
        expect(broken_links).to eq([])
      end
    end
  end

  describe '#parse_log' do
    it 'reports the broken links' do
      spider = Spider.new 'ignored', 'ignored'
      broken_links = spider.parse_log File.read(File.join('spec', 'fixtures', 'wget_broken_links.log'))
      expect(broken_links.size).to eq(4)
      expect(broken_links[3]).to eq('/docs/using/services.html')
    end

    it 'handles the case where there are no broken links' do
      spider = Spider.new 'ignored', 'ignored'
      broken_links = spider.parse_log File.read(File.join('spec', 'fixtures', 'wget_no_broken_links.log'))
      expect(broken_links.size).to eq(0)
    end
  end

end