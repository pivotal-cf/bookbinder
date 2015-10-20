module Bookbinder
  module Config
    module Checkers
      class TopicsChecker
        MissingRequiredKeyError = Class.new(RuntimeError)

        def check(config)
          @config = config

          if invalid_subnavs.any?
            MissingRequiredKeyError.new("Your config.yml is missing required key(s) for subnav(s) #{invalid_subnav_names}. Required keys are #{required_topic_keys.join(", ")}.")
          end
        end

        attr_reader :config

        private

        def invalid_subnavs
          config.subnavs.select { |subnav_config| invalid_topics(subnav_config.topics).any? }
        end

        def invalid_topics(topics)
          topics.map {|topic| topic unless topic.valid? }
        end

        def invalid_subnav_names
          invalid_subnavs.map(&:subnav_name).join(', ')
        end

        def required_topic_keys
          Bookbinder::Config::TopicConfig::CONFIG_REQUIRED_KEYS
        end
      end
    end
  end
end
