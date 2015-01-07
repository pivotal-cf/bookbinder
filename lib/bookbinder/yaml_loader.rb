module Bookbinder

  FileNotFoundError = Class.new(RuntimeError)
  InvalidSyntaxError = Class.new(RuntimeError)

  class YAMLLoader
    def load(path)
      unless File.exist? path
        raise FileNotFoundError.new, "YAML"
      end

      begin
        YAML.load_file(path)
      rescue Psych::SyntaxError => e
        raise InvalidSyntaxError.new e
      end

    end
  end

end

