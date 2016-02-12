module Bookbinder
  module Config
    module Checkers
      class SectionPresenceChecker
        NoSectionsError = Class.new(RuntimeError)

        def check(config)
          if config.sections.none?
            NoSectionsError.new('No sections found in your config.yml. Add sections under the appropriate key(s) and try again.')
          end
        end
      end
    end
  end
end
