require_relative 'section_repository'

module Bookbinder
  module Ingest
    class SectionRepositoryFactory
      def initialize(logger)
        @logger = logger
      end

      def produce(cloner)
        SectionRepository.new(logger, cloner)
      end

      private

      attr_reader :logger
    end
  end
end
