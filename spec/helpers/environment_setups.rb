require_relative '../helpers/dita_ot_installer'

def around_in_dita_ot_env(environment)
  around do |example|
    old_env = environment.clone
    dita_ot_installer = Bookbinder::DitaOTInstaller.new
    environment.update(
        'PATH_TO_DITA_OT_LIBRARY' => dita_ot_installer.install_dita.to_s,
        'JAVA_HOME' => dita_ot_installer.java_home,
        'PATH' => "#{dita_ot_installer.spec_root.join("utilities", "apache-ant-1.9.4", "bin")}:#{ENV['PATH']}"
    )
    begin
      example.run
    ensure
      environment = old_env
    end
  end
end
