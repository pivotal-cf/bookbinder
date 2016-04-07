require_relative '../../../../lib/bookbinder/streams/filter_stream'

module Bookbinder::Streams
  describe FilterStream do
    let(:fake_stream) { double(:stream, puts: nil, :<< => nil) }

    subject { FilterStream.new(/^foo/, fake_stream) }

    it 'should pass through matching lines to puts' do
      subject.puts('foo')
      subject.puts('foobar')
      subject.puts('bar')

      expect(fake_stream).to have_received(:puts).with('foo')
      expect(fake_stream).to have_received(:puts).with('foobar')
      expect(fake_stream).not_to have_received(:puts).with('bar')
    end

    it 'should pass through matching lines to <<' do
      subject << 'foo'
      subject << 'foobar'
      subject << 'bar'

      expect(fake_stream).to have_received(:<<).with('foo')
      expect(fake_stream).to have_received(:<<).with('foobar')
      expect(fake_stream).not_to have_received(:<<).with('bar')
    end
  end
end
