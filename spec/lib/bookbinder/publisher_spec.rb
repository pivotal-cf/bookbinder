require_relative '../../helpers/tmp_dirs'
require_relative '../../helpers/spec_git_accessor'
require_relative '../../helpers/nil_logger'
require_relative '../../../lib/bookbinder/publisher'
require_relative '../../../lib/bookbinder/spider'
require_relative '../../../lib/bookbinder/book'
require_relative '../../../lib/bookbinder/middleman_runner'

module Bookbinder
  describe Publisher do
    describe '#publish' do
      include_context 'tmp_dirs'

      def publish(logger, spider, static_site_generator, final_app_dir, output_dir)
        master_middleman_dir = tmp_subdir 'irrelevant'

        cli_options =   { verbose: false }
        output_paths =  {
              output_dir: output_dir,
              master_middleman_dir: master_middleman_dir,
              final_app_dir: final_app_dir,
              local_repo_dir: nil
        }
        publish_config = {
              sections: [],
              host_for_sitemap: 'example.com',
              pdf: nil,
              book_repo: 'some-repo/some-book',
        }

        publisher = Publisher.new(logger, spider, static_site_generator, SpecGitAccessor)
        publisher.publish(cli_options, output_paths, publish_config)
      end

      context 'when the spider reports broken links' do
        it 'returns false' do
          final_app_dir = tmp_subdir 'final_app'
          output_dir = tmp_subdir 'output'

          logger = NilLogger.new
          spider = Spider.new(logger, app_dir: final_app_dir)
          static_site_generator = MiddlemanRunner.new logger
          allow(static_site_generator).to receive(:run) do |middleman_dir|
            Dir.mkdir File.join(output_dir, 'master_middleman', 'build')
          end

          working_links =  []
          allow(spider).to receive(:generate_sitemap).and_return(working_links)
          allow(spider).to receive(:has_broken_links?).and_return true

          expect(publish(logger, spider, static_site_generator, final_app_dir, output_dir)).to eq false
        end
      end

      it 'returns true when everything is happy' do
        final_app_dir = tmp_subdir 'final_app'
        output_dir = tmp_subdir 'output'

        logger = NilLogger.new
        spider = Spider.new(logger, app_dir: final_app_dir)
        static_site_generator = MiddlemanRunner.new logger
        allow(static_site_generator).to receive(:run) do |middleman_dir|
          Dir.mkdir File.join(output_dir, 'master_middleman', 'build')
        end

        working_links =  []
        allow(spider).to receive(:generate_sitemap).and_return(working_links)
        allow(spider).to receive(:has_broken_links?).and_return false

        expect(publish(logger, spider, static_site_generator, final_app_dir, output_dir)).to eq true
      end
    end
  end
end
