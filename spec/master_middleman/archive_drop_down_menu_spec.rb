require_relative '../../master_middleman/archive_drop_down_menu'

module Bookbinder
  describe ArchiveDropDownMenu do
    it "uses the root menu when at the root path" do
      menu = ArchiveDropDownMenu.new(
        { '.' => ['v2',
                  {'v1.1' => 'great/place'},
                  {'v1.0' => 'notso/greatplace'}] },
        current_path: 'index.html')
      expect(menu.title).to eq('v2')
      expect(menu.dropdown_links).to eq([{'v1.1' => '/great/place'},
                                         {'v1.0' => '/notso/greatplace'}])
    end

    it "defaults to the root menu when at a sub path without special menu" do
      menu = ArchiveDropDownMenu.new(
        { '.' => ['v2.5',
                  {'v1.1' => 'great/place'}] },
        current_path: 'unconfigured/index.html')
      expect(menu.title).to eq('v2.5')
      expect(menu.dropdown_links).to eq([{'v1.1' => '/great/place'}])
    end

    it "uses a subdir menu when at a sub path with a special menu" do
      menu = ArchiveDropDownMenu.new(
        { '.'         => ['not',
                          {'this' => 'one-please'}],
          'some_dir'  => ['v1.0',
                          {'v0.9' => 'old/place'}]},
        current_path: 'some_dir/index.html')
      expect(menu.title).to eq('v1.0')
      expect(menu.dropdown_links).to eq([{'v0.9' => '/old/place'}])
    end

    describe "when misconfigured" do
      context "with nil config" do
        it "provides nil title and empty dropdown links" do
          menu = ArchiveDropDownMenu.new(config = nil, current_path: 'index.html')
          expect(menu.title).to be_nil
          expect(menu.dropdown_links).to be_empty
        end
      end

      context "with a current path having nil versions" do
        it "provides nil title and empty dropdown links" do
          menu = ArchiveDropDownMenu.new({'.' => nil}, current_path: 'index.html')
          expect(menu.title).to be_nil
          expect(menu.dropdown_links).to be_empty
        end
      end

      context "with an empty config hash" do
        it "provides nil title and empty dropdown links" do
          menu = ArchiveDropDownMenu.new({}, current_path: 'index.html')
          expect(menu.title).to be_nil
          expect(menu.dropdown_links).to be_empty
        end
      end
    end

    describe "#empty?" do
      context "when the menu is empty" do
        it "returns true" do
          menu = ArchiveDropDownMenu.new({'.' => nil}, current_path: 'index.html')
          expect(menu.empty?).to eq(true)
        end
      end

      context "when the menu is not empty" do
        it "returns false" do
          menu = ArchiveDropDownMenu.new(
            { '.' => [
              'v2.5',
              {'v1.1' => 'great/place'}
            ] },
            current_path: 'index.html')

          expect(menu.empty?).to eq(false)
        end
      end
    end
  end
end
