$:.push File.expand_path("../lib", __FILE__)

require 'librarian/puppet/simple/version'

Gem::Specification.new do |s|
  s.name = 'librarian-puppet-simple'
  s.version = Librarian::Puppet::Simple::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ['Dan Bode']
  s.email = ['bodepd@gmail.com']
  s.homepage = 'https://github.com/bodepd/librarian-puppet-simple'
  s.summary = 'Bundler for your Puppet modules'
  s.description = 'Simplify deployment of your Puppet infrastructure by
  automatically pulling in modules from the forge and git repositories with
  a single command.'

  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.add_dependency "thor", "~> 0.15"

  s.add_development_dependency "rspec", "~> 2.13"
  s.add_development_dependency "rake", "< 11.0"
end
