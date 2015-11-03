require 'rack'

module Bookbinder
  class RackStatic < Rack::Static
    def route_file(path)
      @urls.kind_of?(Array) && @urls.any? { |url| url.index(path) == 0 }
    end

    def overwrite_file_path(path)
      path_has_trailing_slash?(path) && we_can_serve_index_at_path?(path)
    end

    private

    def path_has_trailing_slash?(path)
      !((path =~ /\/$/).nil?)
    end

    def we_can_serve_index_at_path?(path)
      @index && File.exists?(File.join @file_server.root, path, @index)
    end
  end
end
