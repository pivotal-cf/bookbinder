require_relative '../../../../lib/bookbinder/config/topic_config'

module Bookbinder
  module Config
    describe TopicConfig do
      it 'can return a title' do
        config = { 'title' => 'Learn About This Really Exciting Thing' }

        expect(TopicConfig.new(config).title).
          to eq('Learn About This Really Exciting Thing')
      end

      it 'can return a toc url' do
        config = { 'toc_url' => 'An Overview at This Excellent Url' }

        expect(TopicConfig.new(config).toc_url).
          to eq('An Overview at This Excellent Url')
      end

      it 'is valid with required keys' do
        config = {
          'title' => 'Learn About This Really Exciting Thing',
          'toc_url' => 'An Overview at This Excellent Url'
        }

        expect(TopicConfig.new(config).valid?).to be(true)
      end

      it 'is not valid when missing required keys' do
        config = { 'toc_url' => 'An Overview at This Excellent Url' }

        expect(TopicConfig.new(config).valid?).to be(false)
      end
    end
  end
end
