module GitRepo
  def init_repo(at_dir: nil,
                branch: nil,
                commit_message: nil,
                contents: nil,
                file: nil)
    FileUtils.mkdir(at_dir)
    `#{<<-SCRIPT}`
cd #{at_dir};
git init;
git config user.email "you@example.com"
git config user.name "Your name"
echo foo > bar
git add .
git commit -m "root master commit"
#{create_branch(branch)}
echo #{contents} > #{file}
git add .
git commit -m "#{commit_message}"
git checkout --quiet master
    SCRIPT
  end

  private

  def create_branch(branch)
    "git checkout --quiet -b #{branch}" if branch
  end
end
