# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'intransient_capybara/version'

Gem::Specification.new do |spec|
  spec.name          = "intransient_capybara"
  spec.version       = IntransientCapybara::VERSION
  spec.authors       = ["Seth Ringling"]
  spec.email         = ["sringling@avvo.com"]

  spec.summary       = %q{A set of improvements to Capybara/Poltergeist/PhantomJS test stack that reduces the occurrence transient failures.}
  spec.description   = %q{With improved debuggability, with proper usage and configuration of Capybara/Poltergeist/PhantomJS, and with some improvements on top of it we can greatly reduce the occurrence of transient integration/UI test failures.}
  spec.homepage      = "https://github.com/avvo/intransient_capybara"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.test_files    = spec.files.grep(%r{^(test|s|features)/})

  spec.add_dependency 'capybara', '~> 2.10'
  spec.add_dependency 'poltergeist', '~> 1.11'
  spec.add_dependency 'phantomjs', '~> 2.1'
  spec.add_dependency 'atomic', '~> 1.1'
  spec.add_dependency 'minitest', '~> 5.8'

  spec.add_development_dependency "bundler", "~> 1.17.3"
  spec.add_development_dependency "rake", "~> 12.3.3"
end
