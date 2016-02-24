module Bookbinder
  module Config
    module Checkers
      class ProductsChecker
        MissingProductsKeyError = Class.new(RuntimeError)
        MissingProductIdError = Class.new(RuntimeError)

        def check(config)
          @config = config

          if section_product_ids.count > 0
            if config.products.empty?
              MissingProductsKeyError.new('You must specify at least one product under the products key in config.yml')
            elsif missing_products.count != 0
              MissingProductIdError.new("Your config.yml is missing required product id under the products key. Required product ids are #{missing_products.join(", ")}.")
            end
          end
        end

        attr_reader :config

        private

        def missing_products
          section_product_ids - config.products.map(&:id)
        end

        def section_product_ids
          config.sections.map(&:product_id).compact.uniq
        end
      end
    end
  end
end
