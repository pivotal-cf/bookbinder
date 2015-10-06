require_relative '../../../../lib/bookbinder/config/topic_config'

module Bookbinder
  module Config
    describe TopicConfig do
      it 'can return a title' do
        config = { 'title' => 'Learn About This Really Exciting Thing' }

        expect(TopicConfig.new(config).title).
          to eq('Learn About This Really Exciting Thing')
      end

      it 'can return a toc file' do
        config = { 'toc_file' => 'An Overview at This Excellent Url' }

        expect(TopicConfig.new(config).toc_file).
          to eq('An Overview at This Excellent Url')
      end

      it 'returns relative path' do
        config = { 'toc_file' => 'some/random/dir/index' }

        expect(TopicConfig.new(config).toc_dir_path).
          to eq(Pathname('some/random/dir'))
      end

      it 'returns filename without extension' do
        config = { 'toc_file' => 'some/random/dir/index.html.erb.whatev' }

        expect(TopicConfig.new(config).toc_filename).
          to eq('index')
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
          'toc_file' => 'An Overview at This Excellent Url'
        }

        expect(TopicConfig.new(config).valid?).to be(true)
      end

      it 'is not valid when missing required keys' do
        config = { 'toc_file' => 'An Overview at This Excellent Url' }

        expect(TopicConfig.new(config).valid?).to be(false)
      end
    end
  end
end
