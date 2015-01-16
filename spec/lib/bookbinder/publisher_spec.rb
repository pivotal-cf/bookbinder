require 'webmock/rspec'

require_relative '../../helpers/tmp_dirs'
require_relative '../../helpers/spec_git_accessor'
require_relative '../../helpers/nil_logger'
require_relative '../../helpers/middleman'
require_relative '../../fixtures/repo_fixture'
require_relative '../../../lib/bookbinder/publisher'
require_relative '../../../lib/bookbinder/spider'
require_relative '../../../lib/bookbinder/book'
require_relative '../../../lib/bookbinder/middleman_runner'

module Bookbinder
  describe Publisher do
    describe '#publish' do
      include_context 'tmp_dirs'

      let(:logger) { NilLogger.new }
      let(:spider) { Spider.new(logger, app_dir: final_app_dir) }
      let(:static_site_generator) { MiddlemanRunner.new logger }
      let(:publisher) { Publisher.new(logger, spider, static_site_generator, SpecGitAccessor) }
      let(:output_dir) { tmp_subdir 'output' }
      let(:final_app_dir) { tmp_subdir 'final_app' }
      let(:non_broken_master_middleman_dir) { generate_middleman_with 'non_broken_index.html' }
      let(:dogs_master_middleman_dir) { generate_middleman_with 'dogs_index.html' }
      let(:archive_menu) { {} }
      let(:git_client) { GitClient.new(logger) }
      let(:working_links) { [] }

      context 'unit' do
        before do
          allow(spider).to receive(:generate_sitemap).and_return(working_links)
          allow(spider).to receive(:has_broken_links?)
        end

        let(:master_middleman_dir) { tmp_subdir 'irrelevant' }
        let(:pdf_config) { nil }
        let(:local_repo_dir) { nil }
        let(:book) { 'some-repo/some-book' }
        let(:sections) { [] }
        let(:host_for_sitemap) { 'example.com' }
        let(:archive_menu) { {} }
        let(:template_variables) { {} }
        let(:cli_options) do
          {
              verbose: false
          }
        end
        let(:output_paths) do
          {
              output_dir: output_dir,
              master_middleman_dir: master_middleman_dir,
              final_app_dir: final_app_dir,
              local_repo_dir: local_repo_dir
          }
        end
        let(:publish_config) do
          {
              sections: sections,
              host_for_sitemap: host_for_sitemap,
              pdf: pdf_config,
              book_repo: book,
              archive_menu: archive_menu
          }
        end

        before do
          allow(static_site_generator).to receive(:run) do |middleman_dir|
            Dir.mkdir File.join(output_dir, 'master_middleman', 'build')
          end
        end

        def publish
          publisher.publish(cli_options, output_paths, publish_config)
        end

        it 'sends middlemanRunner the correct arguments to run' do
          expect(static_site_generator).to receive(:run).with(anything,
                                                              anything,
                                                              template_variables,
                                                              local_repo_dir,
                                                              false,
                                                              anything,
                                                              sections,
                                                              host_for_sitemap,
                                                              archive_menu,
                                                              SpecGitAccessor)
          publish
        end

        context 'when the spider reports broken links' do
          before do
            allow(spider).to receive(:has_broken_links?).and_return true
          end

          it 'returns false' do
            expect(publish).to eq false
          end
        end

        it 'returns true when everything is happy' do
          expect(publish).to eq true
        end
      end
    end
  end
end
