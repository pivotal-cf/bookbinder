module Bookbinder
  module Ingest
    DestinationDirectory = Struct.new(:full_repo_name, :desired_destination_dir_name) do
      def to_str
        if desired_destination_dir_name
          desired_destination_dir_name.to_s
        elsif full_repo_name
          full_repo_name.split('/').last
        else
          ""
        end
      end

      alias :to_s :to_str

      def ==(other)
        to_str == other
      end
    end
  end
end
