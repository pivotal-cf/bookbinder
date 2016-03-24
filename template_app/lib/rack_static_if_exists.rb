require 'rack'

module Bookbinder
  class RackStaticIfExists < Rack::Static
    def can_serve(path)
      file_exists?(path) || dir_with_index_exists?(path)
    end

    private

    def file_exists?(path)
      File.file?(File.join(@file_server.root, path))
    end

    def dir_with_index_exists?(path)
      File.directory?(File.join(@file_server.root, path)) && !!@index && file_exists?(File.join(path, @index))
    end
  end
end
