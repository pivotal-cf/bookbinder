module Bookbinder
  module GitRepo
    def init_repo(at_dir: nil,
                  branch: nil,
                  commit_message: "I love commits!",
                  contents: nil,
                  file: nil)
      FileUtils.mkdir_p(File.join(at_dir, File.dirname(file)))
      `#{<<-SCRIPT}`
cd #{at_dir};
git init;
git config user.email "you@example.com"
git config user.name "Your name"
git config receive.denyCurrentBranch "ignore"
echo foo > bar
git add .
git commit -m "root master commit"
#{create_branch(branch)}
echo '#{contents}' > #{file}
git add .
git commit -m "#{commit_message}"
git checkout --quiet master
      SCRIPT
    end

    def init_layout_repo(at_dir: nil,
                         contents: nil)
      FileUtils.mkdir_p("#{at_dir}/source")
      `#{<<-SCRIPT}`
cd #{at_dir};
git init;
git config user.email "you@example.com"
git config user.name "Your name"
git config receive.denyCurrentBranch "ignore"
echo #{contents} > source/index.html.erb
git add .
git commit -m "Commitment!"
git checkout --quiet master
      SCRIPT
    end

    private

    def create_branch(branch)
      "git checkout --quiet -b #{branch}" if branch
    end
  end
end
