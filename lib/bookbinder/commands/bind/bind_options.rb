require_relative '../../sheller'
require_relative '../../streams/colorized_stream'

module Bookbinder
  module Commands
    module BindComponents
      class BindOptions
        def initialize(opts)
          @opts = opts
        end

        def validate!
          raise CliError::InvalidArguments unless arguments_are_valid?
        end

        def ref_override
          'master' if opts.include?('--ignore-section-refs')
        end

        def streams
          {
            out: opts.include?('--verbose') ? $stdout : Sheller::DevNull.new,
            err: Streams::ColorizedStream.new(Colorizer::Colors.red, $stderr)
          }
        end

        private

        attr_accessor :opts

        def arguments_are_valid?
          valid_options = %w(--verbose --ignore-section-refs --dita-flags).to_set
          %w(local remote github).include?(bind_source) && flag_names.to_set.subset?(valid_options)
        end

        def flag_names
          options.map {|o| o.split('=').first}
        end

        def bind_source
          opts.first
        end

        def options
          opts[1..-1]
        end
      end
    end
  end
end
