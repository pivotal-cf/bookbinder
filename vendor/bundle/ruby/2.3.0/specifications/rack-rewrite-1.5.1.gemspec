# -*- encoding: utf-8 -*-
# stub: rack-rewrite 1.5.1 ruby lib

Gem::Specification.new do |s|
  s.name = "rack-rewrite"
  s.version = "1.5.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Travis Jeffery", "John Trupiano"]
  s.date = "2014-12-31"
  s.description = "A rack middleware for enforcing rewrite rules. In many cases you can get away with rack-rewrite instead of writing Apache mod_rewrite rules."
  s.email = "travisjeffery@gmail.com"
  s.extra_rdoc_files = ["LICENSE", "History.rdoc"]
  s.files = ["History.rdoc", "LICENSE"]
  s.homepage = "http://github.com/jtrupiano/rack-rewrite"
  s.rdoc_options = ["--charset=UTF-8"]
  s.rubyforge_project = "johntrupiano"
  s.rubygems_version = "2.5.1"
  s.summary = "A rack middleware for enforcing rewrite rules"

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>, [">= 0"])
      s.add_development_dependency(%q<shoulda>, ["~> 2.10.2"])
      s.add_development_dependency(%q<mocha>, ["~> 0.9.7"])
      s.add_development_dependency(%q<rack>, [">= 0"])
    else
      s.add_dependency(%q<bundler>, [">= 0"])
      s.add_dependency(%q<shoulda>, ["~> 2.10.2"])
      s.add_dependency(%q<mocha>, ["~> 0.9.7"])
      s.add_dependency(%q<rack>, [">= 0"])
    end
  else
    s.add_dependency(%q<bundler>, [">= 0"])
    s.add_dependency(%q<shoulda>, ["~> 2.10.2"])
    s.add_dependency(%q<mocha>, ["~> 0.9.7"])
    s.add_dependency(%q<rack>, [">= 0"])
  end
end
