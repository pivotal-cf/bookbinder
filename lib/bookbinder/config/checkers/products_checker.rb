module Bookbinder
  module Config
    module Checkers
      class ProductsChecker
        MissingRequiredKeyError = Class.new(RuntimeError)
        MissingProductsKeyError = Class.new(RuntimeError)
        MissingProductIdError = Class.new(RuntimeError)

        def check(config)
          @config = config

          if section_product_ids.count > 0
            if config.products.empty?
               MissingProductsKeyError.new('You must specify at least one product under the products key in config.yml')
            elsif missing_products.count != 0
              MissingProductIdError.new("Your config.yml is missing required product id under the products key. Required product ids are #{missing_products.join(", ")}.")
            elsif invalid_products.any?
              MissingRequiredKeyError.new("Your config.yml is missing required key(s) for products #{invalid_product_ids}. Required keys are #{required_product_keys.join(", ")}.")
            end
          end
        end

        attr_reader :config

        private

        def invalid_products
          config.products.map {|product_config| product_config unless product_config.valid? }
        end

        def invalid_product_ids
          invalid_products.map(&:id).join(', ')
        end

        def missing_products
          section_product_ids - config.products.map(&:id)
        end

        def required_product_keys
          Bookbinder::Config::ProductConfig::CONFIG_REQUIRED_KEYS
        end

        def section_product_ids
          config.sections.map(&:product_id).compact.uniq
        end
      end
    end
  end
end
