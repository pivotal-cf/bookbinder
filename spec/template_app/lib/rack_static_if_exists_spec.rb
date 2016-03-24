require_relative '../../../template_app/lib/rack_static_if_exists'

module Bookbinder
  describe RackStaticIfExists do
    subject do
      RackStaticIfExists.new(nil,
        root: File.join(File.dirname(__FILE__), '..', '..', 'fixtures', 'static_file_checking', 'public'),
        index: 'index.html'
      )
    end

    it 'can serve a file that exists' do
      expect(subject.can_serve('/foo.html')).to be(true)
    end

    it 'will not serve a file that does not exist' do
      expect(subject.can_serve('/not_exists.html')).to be(false)
    end

    it 'can serve a folder that exists with an index.html' do
      expect(subject.can_serve('/has_index/')).to be(true)
    end

    it 'will not serve a folder that exists with no index.html' do
      expect(subject.can_serve('/no_index/')).to be(false)
    end

    it 'will not serve a folder that does not exist' do
      expect(subject.can_serve('/no_folder/')).to be(false)
    end
  end
end
