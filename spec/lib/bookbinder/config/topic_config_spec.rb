require_relative '../../../../lib/bookbinder/config/topic_config'

module Bookbinder
  module Config
    describe TopicConfig do
      it 'can return a title' do
        config = { 'title' => 'Learn About This Really Exciting Thing' }

        expect(TopicConfig.new(config).title).
          to eq('Learn About This Really Exciting Thing')
      end

      it 'can return a base path' do
        config = { 'base_path' => 'some/dir' }

        expect(TopicConfig.new(config).base_path).
          to eq(Pathname('some/dir'))
      end

      it 'returns a relative toc path' do
        config = { 'toc_path' => 'dir/index' }

        expect(TopicConfig.new(config).toc_path).
          to eq('dir/index')
      end

      it 'returns full path to toc file' do
        config = { 'base_path' => 'some/random',
                   'toc_path' => 'dir/at/index' }

        expect(TopicConfig.new(config).toc_full_path).
          to eq(Pathname('some/random/dir/at/index'))
      end

      describe 'toc_nav_name' do
        it 'can return a toc nav name' do
          config = { 'toc_nav_name' => 'The Naming of Things' }

          expect(TopicConfig.new(config).toc_nav_name).
            to eq('The Naming of Things')
        end

        it 'defaults to topic title when not provided with a toc_nav_name' do
          config = {
            'title' => 'Learn About This Really Exciting Thing'
          }

          expect(TopicConfig.new(config).toc_nav_name).
            to eq('Learn About This Really Exciting Thing')
        end
      end

      it 'is valid with required keys' do
        config = {
          'title' => 'Learn About This Really Exciting Thing',
          'base_path' => 'Section of Great Stuff',
          'toc_path' => 'An Overview at This Excellent Url'
        }

        expect(TopicConfig.new(config).valid?).to be(true)
      end

      it 'is not valid when missing required keys' do
        config = {}

        expect(TopicConfig.new(config).valid?).to be(false)
      end
    end
  end
end
