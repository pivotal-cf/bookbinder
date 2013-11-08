class Pusher

  include BookbinderLogger

  def push_to_staging(app_dir)
    push 'docs-pivotalone-staging', app_dir, 'cfaccounts+cfdocs@pivotallabs.com', 'hyrax4baseball'
  end

  def push_to_production(app_dir)
    log 'Warning: You are pushing to CF Docs production. Be careful.'.yellow
    push 'docs-pivotalone-prod', app_dir
  end

  private

  def push(space, app_dir, username = nil, password = nil)
    creds_string = (username && password) ? "-u '#{username}' -p '#{password}'" : ''
    Dir.chdir(app_dir) do
      system "~/bin/go-cf login #{creds_string} -a 'https://api.run.pivotal.io' -o 'pivotal' -s '#{space}'"
      system '~/bin/go-cf push docs'
    end
  end

end