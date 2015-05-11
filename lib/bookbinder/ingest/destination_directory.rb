module Bookbinder
  module Ingest
    DestinationDirectory = Struct.new(:full_repo_name, :desired_destination_dir_name) do
      def to_str
        desired_destination_dir_name || full_repo_name.split('/').last
      end

      alias :to_s :to_str

      def ==(other)
        to_str == other
      end
    end
  end
end
