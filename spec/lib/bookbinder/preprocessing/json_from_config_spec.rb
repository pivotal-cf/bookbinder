require_relative '../../../../lib/bookbinder/preprocessing/json_from_config'
require_relative '../../../../lib/bookbinder/config/subnav_config'
require 'json'

module Bookbinder
  module Preprocessing
    describe JsonFromConfig do
      it 'returns formatted json from topics in a subnav config' do
        subnav_config = Config::SubnavConfig.new(
          {'topics' => [
            {'title' => 'Puppy bowls are great'},
            {'title' => 'Almost as good as cheese'}
          ]}
        )

        some_json = {links: [
          {text: 'Puppy bowls are great'},
          {text: 'Almost as good as cheese'}
        ]}.to_json

        expect(JsonFromConfig.new.get_links(subnav_config)).to eq(some_json)
      end
    end
  end
end
