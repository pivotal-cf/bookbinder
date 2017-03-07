# -*- encoding: utf-8 -*-
# stub: fog-aws 0.7.6 ruby lib

Gem::Specification.new do |s|
  s.name = "fog-aws"
  s.version = "0.7.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Josh Lane", "Wesley Beary"]
  s.date = "2015-08-26"
  s.description = "This library can be used as a module for `fog` or as standalone provider\n                        to use the Amazon Web Services in applications.."
  s.email = ["me@joshualane.com", "geemus@gmail.com"]
  s.homepage = "http://github.com/fog/fog-aws"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.5.1"
  s.summary = "Module for the 'fog' gem to support Amazon Web Services."

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>, ["~> 1.6"])
      s.add_development_dependency(%q<rake>, ["~> 10.0"])
      s.add_development_dependency(%q<shindo>, ["~> 0.3"])
      s.add_development_dependency(%q<rubyzip>, ["~> 0.9.9"])
      s.add_runtime_dependency(%q<fog-core>, ["~> 1.27"])
      s.add_runtime_dependency(%q<fog-json>, ["~> 1.0"])
      s.add_runtime_dependency(%q<fog-xml>, ["~> 0.1"])
      s.add_runtime_dependency(%q<ipaddress>, ["~> 0.8"])
    else
      s.add_dependency(%q<bundler>, ["~> 1.6"])
      s.add_dependency(%q<rake>, ["~> 10.0"])
      s.add_dependency(%q<shindo>, ["~> 0.3"])
      s.add_dependency(%q<rubyzip>, ["~> 0.9.9"])
      s.add_dependency(%q<fog-core>, ["~> 1.27"])
      s.add_dependency(%q<fog-json>, ["~> 1.0"])
      s.add_dependency(%q<fog-xml>, ["~> 0.1"])
      s.add_dependency(%q<ipaddress>, ["~> 0.8"])
    end
  else
    s.add_dependency(%q<bundler>, ["~> 1.6"])
    s.add_dependency(%q<rake>, ["~> 10.0"])
    s.add_dependency(%q<shindo>, ["~> 0.3"])
    s.add_dependency(%q<rubyzip>, ["~> 0.9.9"])
    s.add_dependency(%q<fog-core>, ["~> 1.27"])
    s.add_dependency(%q<fog-json>, ["~> 1.0"])
    s.add_dependency(%q<fog-xml>, ["~> 0.1"])
    s.add_dependency(%q<ipaddress>, ["~> 0.8"])
  end
end
