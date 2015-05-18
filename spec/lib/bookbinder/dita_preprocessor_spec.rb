require_relative '../../../lib/bookbinder/config/section_config'
require_relative '../../../lib/bookbinder/dita_preprocessor'

module Bookbinder
  describe DitaPreprocessor do
    it "is applicable to sections configured with a dita subnav" do
      expect(DitaPreprocessor.new(double('formatter'), double('fs'))).
        to be_applicable_to(Config::SectionConfig.new('subnav_template' => 'dita_subnav'))
    end

    it "isn't applicable to anything else" do
      expect(DitaPreprocessor.new(double('formatter'), double('fs'))).
        not_to be_applicable_to(Config::SectionConfig.new('subnav_template' => 'something_else'))
    end
  end
end
