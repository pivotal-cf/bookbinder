require_relative '../../master_middleman/archive_drop_down_menu'

module Bookbinder
  describe ArchiveDropDownMenu do
    it "provides a title AKA the current version" do
      menu = ArchiveDropDownMenu.new(['v2',
                                      {'v1.1' => 'great/place'},
                                      {'v1.0' => 'notso/greatplace'}])
      expect(menu.title).to eq('v2')
    end

    it "sticks slashes on the front of the previous versions' paths" do
      menu = ArchiveDropDownMenu.new(['v2',
                                      {'v1.1' => 'great/place'},
                                      {'v1.0' => 'notso/greatplace'}])
      expect(menu.dropdown_links).to eq([{'v1.1' => '/great/place'},
                                         {'v1.0' => '/notso/greatplace'}])
    end
  end
end
