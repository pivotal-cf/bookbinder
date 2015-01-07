module Bookbinder
  class ArtifactNamer
    def initialize(namespace, build_number, extension, path = '.')
      @namespace = namespace
      @build_number = build_number
      @path = path
      @extension = extension
    end

    def full_path
      File.join(path, filename)
    end

    def filename
      "#{namespace}-#{build_number}.#{extension}"
    end

    private

    attr_reader :namespace, :build_number, :path, :extension
  end
end
