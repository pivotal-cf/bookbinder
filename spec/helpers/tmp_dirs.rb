require 'pathname'
require 'tmpdir'

shared_context 'tmp_dirs' do
  def tmp_subdir(name)
    tmpdir.join(name).tap do |dir|
      FileUtils.mkdir dir
    end
  end

  let(:tmpdir) { Pathname(Dir.mktmpdir) }
end
