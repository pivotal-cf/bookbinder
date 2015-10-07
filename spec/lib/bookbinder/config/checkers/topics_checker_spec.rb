require_relative '../../../../../lib/bookbinder/config/configuration'
require_relative '../../../../../lib/bookbinder/config/checkers/topics_checker'

module Bookbinder
  module Config
    module Checkers
      describe TopicsChecker do
        it 'returns nil when a topic has required keys' do
          config = {
            'subnavs' => [
              { 'topics' => [
                  { 'title' => 'A fabulous topic',
                    'base_path' => 'base of things',
                    'toc_path' => 'toc page file'
                  }
                ]
              }
            ]
          }

          expect(TopicsChecker.new.check(Configuration.parse(config))).to be_nil
        end

        it 'returns an informative error when a topic is missing required keys' do
          config = {
            'subnavs' => [
              { 'topics' => [
                  { }
                ]
              }
            ]
          }

          expect(TopicsChecker.new.
              check(Configuration.parse(config))).to be_a(TopicsChecker::MissingRequiredKeyError)
        end
      end
    end
  end
end
