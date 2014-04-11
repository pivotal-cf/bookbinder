def around_with_fixture_repo(&block)
  around do |spec|
    temp_library = tmp_subdir 'repositories'
    FileUtils.cp_r File.join(RepoFixture.repos_dir, '.'), temp_library
    FileUtils.cd(File.join(temp_library, 'book')) do
      block.call(spec)
    end
  end
end

module SpecHelperMethods
  def expect_to_receive_and_return_real_now(subject, method, *args)
    real_obj = subject.public_send(method, *args)
    expect(subject).to receive(method).with(*args).and_return(real_obj)
    real_obj
  end
end
