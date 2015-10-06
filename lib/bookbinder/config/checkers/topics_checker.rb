module Bookbinder
  module Config
    module Checkers
      class TopicsChecker
        MissingRequiredKeyError = Class.new(RuntimeError)

        def check(config)
          @config = config

          if invalid_subnavs.any?
            MissingRequiredKeyError.new("Your config.yml is missing required key(s) for subnav(s) #{invalid_subnav_names}. Required keys for subnav topics are toc_file and title.")
          end
        end

        attr_reader :config

        private

        def invalid_subnavs
          config.subnavs.select { |subnav_config| invalid_topics(subnav_config.topics).any? }
        end

        def invalid_topics(topics)
          topics.reject {|topic| topic.toc_file && topic.title}
        end

        def invalid_subnav_names
          invalid_subnavs.map(&:name).join(', ')
        end
      end
    end
  end
end
