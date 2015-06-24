module Bookbinder
  module Config
    module Checkers
      class DitaSectionChecker
        DitamapLocationError = Class.new(RuntimeError)

        def check(config)
          if none_with_pred?(dita_sections(config)) { |s|
            s.preprocessor_config['ditamap_location']
          }
            DitamapLocationError.new(
              "You must have at least one 'ditamap_location' key in dita_sections."
            )
          end
        end

        private

        def none_with_pred?(coll, &block)
          coll.any? && coll.none?(&block)
        end

        def dita_sections(config)
          config.sections.select {|s|
            s.preprocessor_config.has_key?('ditamap_location')
          }
        end
      end
    end
  end
end
