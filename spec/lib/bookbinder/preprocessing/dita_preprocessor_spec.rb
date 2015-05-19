require_relative '../../../../lib/bookbinder/config/section_config'
require_relative '../../../../lib/bookbinder/preprocessing/dita_preprocessor'

module Bookbinder
  module Preprocessing
    describe DitaPreprocessor do
      it "is applicable to sections configured with a dita subnav" do
        expect(DitaPreprocessor.new(double('formatter'), double('fs'), double('command creator'), double('sheller'))).
          to be_applicable_to(Config::SectionConfig.new('subnav_template' => 'dita_subnav'))
      end

      it "isn't applicable to anything else" do
        expect(DitaPreprocessor.new(double('formatter'), double('fs'), double('command creator'), double('sheller'))).
          not_to be_applicable_to(Config::SectionConfig.new('subnav_template' => 'something_else'))
      end
    end
  end
end
