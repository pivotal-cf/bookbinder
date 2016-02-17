module Bookbinder
  module Config
    module Checkers
      class SubnavTopicsChecker
        MissingRequiredKeyError = Class.new(RuntimeError)

        def check(config)
          @config = config

          if invalid_products.any?
            MissingRequiredKeyError.new("Your config.yml is missing required key(s) for subnav_topics in product id(s) #{invalid_product_ids}. Required keys are #{required_topic_keys.join(", ")}.")
          end
        end

        attr_reader :config

        private

        def invalid_products
          config.products.select { |product_config| invalid_topics(product_config.subnav_topics).any? }
        end

        def invalid_topics(topics)
          topics.map {|topic| topic unless topic.valid? }
        end

        def invalid_product_ids
          invalid_products.map(&:id).join(', ')
        end

        def required_topic_keys
          Bookbinder::Config::TopicConfig::CONFIG_REQUIRED_KEYS
        end
      end
    end
  end
end
