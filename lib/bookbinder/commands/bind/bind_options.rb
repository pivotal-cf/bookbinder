require_relative '../../sheller'

module Bookbinder
  module Commands
    module BindComponents
      class BindOptions
        def initialize(opts, base_streams)
          @opts = opts
          @base_streams = base_streams
        end

        def validate!
          raise CliError::InvalidArguments unless arguments_are_valid?
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
            out: verbose? ? base_streams[:out] : Sheller::DevNull.new,
          )
        end

        def verbose?
          options.include?('--verbose')
        end

        private

        attr_accessor :base_streams, :opts

        def arguments_are_valid?
          %w(local remote github).include?(bind_source) && flag_names.subset?(valid_options)
        end

        def valid_options
          %w(--verbose --ignore-section-refs --dita-flags).to_set
        end

        def flag_names
          options.map {|o| o.split('=').first}.to_set
        end
      end
    end
  end
end
