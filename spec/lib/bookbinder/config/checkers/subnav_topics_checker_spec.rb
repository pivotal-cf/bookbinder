require_relative '../../../../../lib/bookbinder/config/configuration'
require_relative '../../../../../lib/bookbinder/config/checkers/subnav_topics_checker'

module Bookbinder
  module Config
    module Checkers
      describe SubnavTopicsChecker do
        it 'returns nil when a subnav topic has required keys' do
          config = {
            'products' => [
              { 'subnav_topics' => [
                  { 'title' => 'A fabulous topic',
                    'base_path' => 'base of things',
                    'toc_path' => 'toc page file'
                  }
                ]
              }
            ]
          }

          expect(SubnavTopicsChecker.new.check(Configuration.parse(config))).to be_nil
        end

        it 'returns an informative error when a subnav topic is missing required keys' do
          config = {
            'products' => [
              { 'subnav_topics' => [
                  { }
                ]
              }
            ]
          }

          expect(SubnavTopicsChecker.new.
              check(Configuration.parse(config))).to be_a(SubnavTopicsChecker::MissingRequiredKeyError)
        end
      end
    end
  end
end
