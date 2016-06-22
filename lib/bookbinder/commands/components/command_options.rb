require_relative '../../sheller'
require_relative '../../colorizer'
require_relative '../../streams/colorized_stream'
require_relative '../../streams/filter_stream'

module Bookbinder
  module Commands
    module Components
      class CommandOptions
        def initialize(opts, base_streams, verbose = false)
          @opts = opts
          @base_streams = base_streams
          @verbosity = verbose
        end

        def bind_source
          opts.first
        end

        def local_repo_dir
          File.expand_path('..') if bind_source == 'local'
        end

        def options
          opts[1..-1]
        end

        def ref_override
          'master' if options.include?('--ignore-section-refs')
        end

        def streams
          base_streams.merge(
            out: verbosity ? base_streams[:out] :
              Streams::FilterStream.new(/^(?:\s*error|Invalid CSS|Undefined mixin|\/)/i, Streams::ColorizedStream.new(Colorizer::Colors.red, base_streams[:out])),
          )
        end

        private

        attr_accessor :base_streams, :opts, :verbosity
      end
    end
  end
end
