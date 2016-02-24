require_relative '../../../../../lib/bookbinder/config/checkers/products_checker'
require_relative '../../../../../lib/bookbinder/config/configuration'
require_relative '../../../../../lib/bookbinder/local_filesystem_accessor'

module Bookbinder
  module Config
    module Checkers
      describe ProductsChecker do
        context 'when a product id is specified' do
          context 'when there is no products key' do
            it 'returns an informative error' do
              config = {
                'sections' => [
                  {
                    'product_id' => 'product-id'
                  }
                ]
              }

              expect(ProductsChecker.new.
                  check(Configuration.parse(config))).to be_a(ProductsChecker::MissingProductsKeyError)
            end
          end

          context 'and the product_id is not one of the product ids' do
            it 'returns an informative error' do
              config = {
                'sections' => [
                  {
                    'product_id' => 'product-id'
                  }
                ],
                'products' => [
                  { 'id' => 'fake-product-id' },
                  { 'id' => 'other-product-id' }
                ]
              }
              expect(ProductsChecker.new.
                  check(Configuration.parse(config))).to be_a(ProductsChecker::MissingProductIdError)
            end
          end

          context 'and the product id is in the products key' do
            it 'returns nil' do
              config = {
                'sections' => [
                  { 'product_id' => 'product-id' },
                  { 'product_id' => 'other-group' }
                ],
                'products' => [
                  { 'id' => 'other-group', 'subnav_topics' => [] },
                  { 'id' => 'product-id', 'subnav_topics' => [] }
                ]
              }
              expect(ProductsChecker.new.
                  check(Configuration.parse(config))).to be_nil
            end
          end
        end

        context 'when there are no products' do
          it 'returns nil' do
            config = {
              'sections' => [
                { 'some' => 'thing' }
              ]
            }
            expect(ProductsChecker.new.check(Configuration.parse(config))).to be_nil
          end
        end
      end
    end
  end
end
