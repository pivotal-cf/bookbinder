# -*- encoding: utf-8 -*-
# stub: fast_blank 1.0.0 ruby lib
# stub: ext/fast_blank/extconf.rb

Gem::Specification.new do |s|
  s.name = "fast_blank"
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Sam Saffron"]
  s.date = "2015-08-03"
  s.description = "Provides a C-optimized method for determining if a string is blank"
  s.email = "sam.saffron@gmail.com"
  s.extensions = ["ext/fast_blank/extconf.rb"]
  s.files = ["ext/fast_blank/extconf.rb"]
  s.homepage = "https://github.com/SamSaffron/fast_blank"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.5.1"
  s.summary = "Fast String blank? implementation"

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake-compiler>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
    else
      s.add_dependency(%q<rake-compiler>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 0"])
    end
  else
    s.add_dependency(%q<rake-compiler>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 0"])
  end
end
