module Bookbinder
  class DitaSectionChecker
    DitamapLocationError = Class.new(RuntimeError)

    def check(config)
      dita_sections = config['dita_sections'].to_a

      sum = 0
      dita_sections.each do |section|
        if section['ditamap_location']
          sum += 1
        end
      end

      if !dita_sections.empty? && (sum < 1)
        DitamapLocationError.new "You must have at least one 'ditamap_location' key in dita_sections."
      end
    end
  end
end
