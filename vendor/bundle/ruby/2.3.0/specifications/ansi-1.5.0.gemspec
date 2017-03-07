# -*- encoding: utf-8 -*-
# stub: ansi 1.5.0 ruby lib

Gem::Specification.new do |s|
  s.name = "ansi"
  s.version = "1.5.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Thomas Sawyer", "Florian Frank"]
  s.date = "2015-01-17"
  s.description = "The ANSI project is a superlative collection of ANSI escape code related libraries eabling ANSI colorization and stylization of console output. Byte for byte ANSI is the best ANSI code library available for the Ruby programming language."
  s.email = ["transfire@gmail.com"]
  s.extra_rdoc_files = ["LICENSE.txt", "NOTICE.md", "README.md", "HISTORY.md", "DEMO.md"]
  s.files = ["DEMO.md", "HISTORY.md", "LICENSE.txt", "NOTICE.md", "README.md"]
  s.homepage = "http://rubyworks.github.com/ansi"
  s.licenses = ["BSD-2-Clause"]
  s.rubygems_version = "2.5.1"
  s.summary = "ANSI at your fingertips!"

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<mast>, [">= 0"])
      s.add_development_dependency(%q<indexer>, [">= 0"])
      s.add_development_dependency(%q<ergo>, [">= 0"])
      s.add_development_dependency(%q<qed>, [">= 0"])
      s.add_development_dependency(%q<ae>, [">= 0"])
      s.add_development_dependency(%q<lemon>, [">= 0"])
    else
      s.add_dependency(%q<mast>, [">= 0"])
      s.add_dependency(%q<indexer>, [">= 0"])
      s.add_dependency(%q<ergo>, [">= 0"])
      s.add_dependency(%q<qed>, [">= 0"])
      s.add_dependency(%q<ae>, [">= 0"])
      s.add_dependency(%q<lemon>, [">= 0"])
    end
  else
    s.add_dependency(%q<mast>, [">= 0"])
    s.add_dependency(%q<indexer>, [">= 0"])
    s.add_dependency(%q<ergo>, [">= 0"])
    s.add_dependency(%q<qed>, [">= 0"])
    s.add_dependency(%q<ae>, [">= 0"])
    s.add_dependency(%q<lemon>, [">= 0"])
  end
end
