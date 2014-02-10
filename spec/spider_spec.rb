require 'spec_helper'

describe Spider do

  include_context 'tmp_dirs'

  describe '#has_broken_links?' do
    let(:output_dir) { tmp_subdir 'output' }
    let(:final_app_dir) { tmp_subdir 'final_app' }
    let(:log_file) { File.join(output_dir, 'wget.log') }
    let(:portal_page) { File.join('spec', 'fixtures', 'non_broken_index.html') }

    let(:spider) do
      public_directory = File.join(final_app_dir, 'public')
      FileUtils.mkdir_p public_directory
      FileUtils.cp_r 'template_app/.', final_app_dir
      FileUtils.cp portal_page, File.join(public_directory, 'index.html')
      spider = Spider.new final_app_dir
    end

    it 'returns an false when there are no broken links' do
      expect(spider.has_broken_links?).to be_false
    end
  end

  describe '#generate_sitemap' do
    let(:public_dir) { tmp_subdir 'public' }
    let(:intermediate_dir) { File.join('spec', 'fixtures') }
    let(:log_file) { File.join(intermediate_dir, 'wget_broken_links.log') }
    let(:spider) { Spider.new 'some_final_app_dir', log_file }
    let(:host) { 'example.com' }

    it 'generates a sitemap' do
      spider.generate_sitemap host, public_dir

      sitemap = File.read File.join(public_dir, 'sitemap.txt')
      expect(sitemap).to eq <<MAP
http://#{host}/index.html
http://#{host}/deploy-apps-docs/index.html
http://#{host}/extend-cf-docs/index.html
http://#{host}/ops-guide-docs/index.html
http://#{host}/administer-cf-docs/index.html
http://#{host}/pcf-docs/index.html
http://#{host}/docs/using/services.html
http://#{host}/docs/running/managing-cf/index.html
http://#{host}/docs/reference/cc-api.html
http://#{host}/getting_started.html
http://#{host}/private_networks.html
http://#{host}/pcf-docs/guide_tempest.html
http://#{host}/pcf-docs/troubleshooting.html
http://#{host}/getting-started/hawq.html
http://#{host}/getting-started/Hive.html
http://#{host}/getting-started/pig.html
MAP
    end
  end
end
