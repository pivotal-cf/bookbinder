module Bookbinder
  class BlueGreenApp
    def initialize(name)
      @name = name.strip
    end

    def ==(other)
      to_s == other.to_s
    end

    def to_s
      name
    end

    def with_flipped_name
      if name.match(/green$/)
        BlueGreenApp.new(name.sub(/green$/, 'blue'))
      else
        BlueGreenApp.new(name.sub(/blue$/, 'green'))
      end
    end

    private

    attr_reader :name
  end
end
