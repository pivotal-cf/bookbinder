require_relative '../../../../lib/bookbinder/config/subnav_config'

module Bookbinder
  module Config
    describe SubnavConfig do
      it 'can return a subnav name' do
        config = {'name' => 'mysubnav'}

        expect(SubnavConfig.new(config).name).
          to eq('mysubnav')
      end

      it 'returns an empty array when topic titles are not specified' do
        config = { 'topics' => nil }

        expect(SubnavConfig.new(config).topics).
          to eq([])
      end

      it 'is valid with required keys' do
        config = { 'topics' => [], 'name' => 'elena'}

        expect(SubnavConfig.new(config).valid?).to be(true)
      end

      it 'is not valid when missing required keys' do
        config = { 'topics' => [] }

        expect(SubnavConfig.new(config).valid?).to be(false)
      end

      describe 'topics' do
        it 'returns an array of TopicConfig objects in the order specified' do
          config = {
            'topics' => [
              {'title' => 'Learn About This Really Exciting Thing'}
            ]
          }

          expect(SubnavConfig.new(config).topics[0]).to be_an_instance_of(TopicConfig)
        end
      end

      describe 'subnav exclusions' do
        it 'returns an array of html attributes to exclude' do
          config = { 'subnav_exclusions' => ['this', '.that'] }

          expect(SubnavConfig.new(config).subnav_exclusions). to match_array(['this', '.that'])
        end
      end
    end
  end
end
