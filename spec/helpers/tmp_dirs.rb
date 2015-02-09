require 'pathname'
require 'tmpdir'

shared_context 'tmp_dirs' do
  def tmp_subdir(name)
    tmpdir.join(name).tap do |dir|
      FileUtils.mkdir_p dir
    end
  end

  def tmpdir
    @tmpdir ||= Pathname(Dir.mktmpdir)
  end
end
