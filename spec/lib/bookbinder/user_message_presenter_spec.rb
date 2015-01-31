require_relative '../../../lib/bookbinder/user_message_presenter'
require_relative '../../../lib/bookbinder/colorizer'
require_relative '../../../lib/bookbinder/user_message'

module Bookbinder
  describe UserMessagePresenter do
    it 'presents an error message in red' do
      colorizer = Colorizer.new
      user_message_presenter = UserMessagePresenter.new(colorizer)
      user_message = UserMessage.new('this is a message in red', EscalationType.error)

      expect(user_message_presenter.get_error user_message).to eq("\e[31mthis is a message in red\e[0m")
    end
  end
end