require_relative '../../../../lib/bookbinder/config/product_config'

module Bookbinder
  module Config
    describe ProductConfig do
      it 'can return a product id' do
        config = {'id' => 'my_product'}

        expect(ProductConfig.new(config).id).
          to eq('my_product')
      end

      it 'can return a product id as subnav name' do
        config = {'id' => 'my_product'}

        expect(ProductConfig.new(config).subnav_name).
            to eq('my_product')
      end

      it 'can return a pdf config name' do
        config = {'pdf_config' => 'mypdfconfig'}

        expect(ProductConfig.new(config).pdf_config).
          to eq('mypdfconfig')
      end

      it 'returns an empty array when topic titles are not specified' do
        config = { 'subnav_topics' => nil }

        expect(ProductConfig.new(config).subnav_topics).
          to eq([])
      end

      it 'is valid with required keys' do
        config = { 'id' => 'elena'}

        expect(ProductConfig.new(config).valid?).to be(true)
      end

      it 'is not valid when missing required keys' do
        config = { 'subnav_topics' => [] }

        expect(ProductConfig.new(config).valid?).to be(false)
      end

      describe '#specifies_subnav?' do
        it 'returns false if no topics specified' do
          expect(ProductConfig.new({}).specifies_subnav?).to be(false)
        end

        it 'returns true if topics specified' do
          expect(ProductConfig.new({'subnav_topics' => ['fake topic']}).specifies_subnav?).to be(true)
        end
      end

      describe '#subnav_topics' do
        it 'returns an array of TopicConfig objects in the order specified' do
          config = {
            'subnav_topics' => [
              {'title' => 'Learn About This Really Exciting Thing'}
            ]
          }

          expect(ProductConfig.new(config).subnav_topics[0]).to be_an_instance_of(TopicConfig)
        end
      end

      describe 'subnav exclusions' do
        it 'can return an array of html attributes to exclude' do
          config = { 'subnav_exclusions' => ['this', '.that'] }

          expect(ProductConfig.new(config).subnav_exclusions). to match_array(['this', '.that'])
        end
      end
    end
  end
end
