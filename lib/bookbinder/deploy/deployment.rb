module Bookbinder
  module Deploy
    class Deployment
      attr_reader :app_dir, :build_number, :cf_credentials

      def initialize(app_dir: nil,
                     aws_credentials: nil,
                     book_repo: nil,
                     build_number: nil,
                     cf_credentials: nil)
        @app_dir = app_dir
        @aws_credentials = aws_credentials
        @book_repo = book_repo
        @build_number = build_number
        @cf_credentials = cf_credentials
      end

      def artifact_filename
        artifact.filename
      end

      def artifact_full_path
        artifact.full_path
      end

      def aws_access_key
        aws_credentials.access_key
      end

      def aws_secret_key
        aws_credentials.secret_key
      end

      def flat_routes
        cf_credentials.flat_routes
      end

      def green_builds_bucket
        aws_credentials.green_builds_bucket
      end

      def namespace
        Ingest::DestinationDirectory.new(book_repo)
      end

      private

      attr_reader :aws_credentials, :book_repo

      def artifact
        Artifact.new(namespace, build_number, 'log', '/tmp')
      end
    end
  end
end
