require_relative '../../../../lib/bookbinder/config/subnav_config'

module Bookbinder
  module Config
    describe SubnavConfig do
      it 'can return a subnav name' do
        expect(SubnavConfig.new({'name' => 'mysubnav'}).name).
          to eq('mysubnav')
      end

      it 'can return topics in the order specified' do
        config = {
          'topics' => [
            {'title' => 'Learn About This Really Exciting Thing'},
            {'title' => 'This Thing Is Even Better'}
          ]
        }

        expect(SubnavConfig.new(config).topics).
          to eq(config['topics'])
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
    end
  end
end
