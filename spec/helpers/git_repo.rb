module GitRepo
  def init_repo(at_dir: nil, file: nil, contents: nil, commit_message: nil)
    FileUtils.mkdir(at_dir)
    `#{<<-SCRIPT}`
      cd #{at_dir};
      git init;
      git config user.email "you@example.com"
      git config user.name "Your name"
      echo #{contents} > #{file}; git add .; git commit -m "#{commit_message}"
    SCRIPT
  end
end
