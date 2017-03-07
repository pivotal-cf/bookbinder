# -*- encoding: utf-8 -*-
# stub: memoist 0.15.0 ruby lib

Gem::Specification.new do |s|
  s.name = "memoist"
  s.version = "0.15.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Joshua Peek", "Tarmo T\u{e4}nav", "Jeremy Kemper", "Eugene Pimenov", "Xavier Noria", "Niels Ganser", "Carl Lerche & Yehuda Katz", "jeem", "Jay Pignata", "Damien Mathieu", "Jos\u{e9} Valim", "Matthew Rudy Jacobs"]
  s.date = "2016-08-23"
  s.email = ["josh@joshpeek.com", "tarmo@itech.ee", "jeremy@bitsweat.net", "libc@mac.com", "fxn@hashref.com", "niels@herimedia.co", "wycats@gmail.com", "jeem@hughesorama.com", "john.pignata@gmail.com", "42@dmathieu.com", "jose.valim@gmail.com", "matthewrudyjacobs@gmail.com"]
  s.homepage = "https://github.com/matthewrudy/memoist"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.5.1"
  s.summary = "memoize methods invocation"

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<benchmark-ips>, [">= 0"])
      s.add_development_dependency(%q<bundler>, [">= 0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<minitest>, ["~> 5.5.1"])
    else
      s.add_dependency(%q<benchmark-ips>, [">= 0"])
      s.add_dependency(%q<bundler>, [">= 0"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<minitest>, ["~> 5.5.1"])
    end
  else
    s.add_dependency(%q<benchmark-ips>, [">= 0"])
    s.add_dependency(%q<bundler>, [">= 0"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<minitest>, ["~> 5.5.1"])
  end
end
