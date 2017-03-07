# -*- encoding: utf-8 -*-
# stub: middleman-core 4.1.10 ruby lib

Gem::Specification.new do |s|
  s.name = "middleman-core"
  s.version = "4.1.10"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Thomas Reynolds", "Ben Hollis", "Karl Freeman"]
  s.date = "2016-07-11"
  s.description = "A static site generator. Provides dozens of templating languages (Haml, Sass, Compass, Slim, CoffeeScript, and more). Makes minification, compression, cache busting, Yaml data (and more) an easy part of your development cycle."
  s.email = ["me@tdreyno.com", "ben@benhollis.net", "karlfreeman@gmail.com"]
  s.homepage = "http://middlemanapp.com"
  s.licenses = ["MIT"]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0.0")
  s.rubygems_version = "2.5.1"
  s.summary = "Hand-crafted frontend development"

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<bundler>, ["~> 1.1"])
      s.add_runtime_dependency(%q<rack>, ["< 2.0", ">= 1.4.5"])
      s.add_runtime_dependency(%q<tilt>, ["~> 1.4.1"])
      s.add_runtime_dependency(%q<erubis>, [">= 0"])
      s.add_runtime_dependency(%q<fast_blank>, [">= 0"])
      s.add_runtime_dependency(%q<parallel>, [">= 0"])
      s.add_runtime_dependency(%q<servolux>, [">= 0"])
      s.add_runtime_dependency(%q<dotenv>, [">= 0"])
      s.add_runtime_dependency(%q<activesupport>, ["~> 4.2"])
      s.add_runtime_dependency(%q<padrino-helpers>, ["~> 0.13.0"])
      s.add_runtime_dependency(%q<addressable>, ["~> 2.3"])
      s.add_runtime_dependency(%q<memoist>, ["~> 0.14"])
      s.add_runtime_dependency(%q<listen>, ["~> 3.0.0"])
      s.add_development_dependency(%q<capybara>, ["~> 2.5.0"])
      s.add_runtime_dependency(%q<i18n>, ["~> 0.7.0"])
      s.add_runtime_dependency(%q<fastimage>, ["~> 2.0"])
      s.add_runtime_dependency(%q<sass>, [">= 3.4"])
      s.add_runtime_dependency(%q<uglifier>, ["~> 3.0"])
      s.add_runtime_dependency(%q<execjs>, ["~> 2.0"])
      s.add_runtime_dependency(%q<contracts>, ["~> 0.13.0"])
      s.add_runtime_dependency(%q<hashie>, ["~> 3.4"])
      s.add_runtime_dependency(%q<hamster>, ["~> 3.0"])
      s.add_runtime_dependency(%q<backports>, ["~> 3.6"])
    else
      s.add_dependency(%q<bundler>, ["~> 1.1"])
      s.add_dependency(%q<rack>, ["< 2.0", ">= 1.4.5"])
      s.add_dependency(%q<tilt>, ["~> 1.4.1"])
      s.add_dependency(%q<erubis>, [">= 0"])
      s.add_dependency(%q<fast_blank>, [">= 0"])
      s.add_dependency(%q<parallel>, [">= 0"])
      s.add_dependency(%q<servolux>, [">= 0"])
      s.add_dependency(%q<dotenv>, [">= 0"])
      s.add_dependency(%q<activesupport>, ["~> 4.2"])
      s.add_dependency(%q<padrino-helpers>, ["~> 0.13.0"])
      s.add_dependency(%q<addressable>, ["~> 2.3"])
      s.add_dependency(%q<memoist>, ["~> 0.14"])
      s.add_dependency(%q<listen>, ["~> 3.0.0"])
      s.add_dependency(%q<capybara>, ["~> 2.5.0"])
      s.add_dependency(%q<i18n>, ["~> 0.7.0"])
      s.add_dependency(%q<fastimage>, ["~> 2.0"])
      s.add_dependency(%q<sass>, [">= 3.4"])
      s.add_dependency(%q<uglifier>, ["~> 3.0"])
      s.add_dependency(%q<execjs>, ["~> 2.0"])
      s.add_dependency(%q<contracts>, ["~> 0.13.0"])
      s.add_dependency(%q<hashie>, ["~> 3.4"])
      s.add_dependency(%q<hamster>, ["~> 3.0"])
      s.add_dependency(%q<backports>, ["~> 3.6"])
    end
  else
    s.add_dependency(%q<bundler>, ["~> 1.1"])
    s.add_dependency(%q<rack>, ["< 2.0", ">= 1.4.5"])
    s.add_dependency(%q<tilt>, ["~> 1.4.1"])
    s.add_dependency(%q<erubis>, [">= 0"])
    s.add_dependency(%q<fast_blank>, [">= 0"])
    s.add_dependency(%q<parallel>, [">= 0"])
    s.add_dependency(%q<servolux>, [">= 0"])
    s.add_dependency(%q<dotenv>, [">= 0"])
    s.add_dependency(%q<activesupport>, ["~> 4.2"])
    s.add_dependency(%q<padrino-helpers>, ["~> 0.13.0"])
    s.add_dependency(%q<addressable>, ["~> 2.3"])
    s.add_dependency(%q<memoist>, ["~> 0.14"])
    s.add_dependency(%q<listen>, ["~> 3.0.0"])
    s.add_dependency(%q<capybara>, ["~> 2.5.0"])
    s.add_dependency(%q<i18n>, ["~> 0.7.0"])
    s.add_dependency(%q<fastimage>, ["~> 2.0"])
    s.add_dependency(%q<sass>, [">= 3.4"])
    s.add_dependency(%q<uglifier>, ["~> 3.0"])
    s.add_dependency(%q<execjs>, ["~> 2.0"])
    s.add_dependency(%q<contracts>, ["~> 0.13.0"])
    s.add_dependency(%q<hashie>, ["~> 3.4"])
    s.add_dependency(%q<hamster>, ["~> 3.0"])
    s.add_dependency(%q<backports>, ["~> 3.6"])
  end
end
