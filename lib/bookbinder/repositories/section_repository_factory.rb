require_relative '../ingest/section_repository'

module Bookbinder
  module Repositories
    class SectionRepositoryFactory
      def initialize(logger)
        @logger = logger
      end

      def produce(cloner)
        Ingest::SectionRepository.new(logger, cloner)
      end

      private

      attr_reader :logger
    end
  end
end
