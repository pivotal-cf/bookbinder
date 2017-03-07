# -*- encoding: utf-8 -*-
# stub: license_finder 2.1.2 ruby lib

Gem::Specification.new do |s|
  s.name = "license_finder"
  s.version = "2.1.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Jacob Maine", "Matthew Kane Parker", "Ian Lesperance", "David Edwards", "Paul Meskers", "Brent Wheeldon", "Trevor John", "David Tengdin", "William Ramsey", "David Dening", "Geoff Pleiss", "Mike Chinigo", "Mike Dalessio"]
  s.date = "2016-06-10"
  s.description = "    LicenseFinder works with your package managers to find\n    dependencies, detect the licenses of the packages in them, compare\n    those licenses against a user-defined whitelist, and give you an\n    actionable exception report.\n"
  s.email = ["labs-commoncode@pivotal.io"]
  s.executables = ["license_finder", "license_finder_pip.py"]
  s.files = ["bin/license_finder", "bin/license_finder_pip.py"]
  s.homepage = "https://github.com/pivotal/LicenseFinder"
  s.licenses = ["MIT"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3")
  s.rubygems_version = "2.5.1"
  s.summary = "Audit the OSS licenses of your application's dependencies."

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<bundler>, [">= 0"])
      s.add_runtime_dependency(%q<thor>, [">= 0"])
      s.add_runtime_dependency(%q<httparty>, [">= 0"])
      s.add_runtime_dependency(%q<xml-simple>, [">= 0"])
      s.add_runtime_dependency(%q<rubyzip>, [">= 0"])
      s.add_development_dependency(%q<capybara>, ["~> 2.0.0"])
      s.add_development_dependency(%q<fakefs>, ["~> 0.6.7"])
      s.add_development_dependency(%q<pry>, [">= 0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<rspec>, ["~> 3"])
      s.add_development_dependency(%q<rspec-its>, [">= 0"])
      s.add_development_dependency(%q<webmock>, ["~> 1.13"])
      s.add_development_dependency(%q<mime-types>, ["< 3.0"])
    else
      s.add_dependency(%q<bundler>, [">= 0"])
      s.add_dependency(%q<thor>, [">= 0"])
      s.add_dependency(%q<httparty>, [">= 0"])
      s.add_dependency(%q<xml-simple>, [">= 0"])
      s.add_dependency(%q<rubyzip>, [">= 0"])
      s.add_dependency(%q<capybara>, ["~> 2.0.0"])
      s.add_dependency(%q<fakefs>, ["~> 0.6.7"])
      s.add_dependency(%q<pry>, [">= 0"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<rspec>, ["~> 3"])
      s.add_dependency(%q<rspec-its>, [">= 0"])
      s.add_dependency(%q<webmock>, ["~> 1.13"])
      s.add_dependency(%q<mime-types>, ["< 3.0"])
    end
  else
    s.add_dependency(%q<bundler>, [">= 0"])
    s.add_dependency(%q<thor>, [">= 0"])
    s.add_dependency(%q<httparty>, [">= 0"])
    s.add_dependency(%q<xml-simple>, [">= 0"])
    s.add_dependency(%q<rubyzip>, [">= 0"])
    s.add_dependency(%q<capybara>, ["~> 2.0.0"])
    s.add_dependency(%q<fakefs>, ["~> 0.6.7"])
    s.add_dependency(%q<pry>, [">= 0"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<rspec>, ["~> 3"])
    s.add_dependency(%q<rspec-its>, [">= 0"])
    s.add_dependency(%q<webmock>, ["~> 1.13"])
    s.add_dependency(%q<mime-types>, ["< 3.0"])
  end
end
