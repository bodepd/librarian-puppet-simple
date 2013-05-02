$:.push File.expand_path("../lib", __FILE__)

require 'librarian/puppet/version'

Gem::Specification.new do |s|
  s.name = 'librarian-puppet-simple
  s.version = '0.0.1'
  s.platform = Gem::Platform::RUBY
  s.authors = ['Dan Bode']
  s.email = ['bodepd@gmail.com']
  s.homepage = 'https://github.com/bodepd/librarian-puppet-simple'
  s.summary = 'Bundler for your Puppet modules'
  s.description = 'Simplify deployment of your Puppet infrastructure by
  automatically pulling in modules from the forge and git repositories with
  a single command.'

  s.files = [
    '.gitignore',
    'LICENSE',
    'README.md',
  ] + Dir['{bin,lib}/**/*']

  s.executables = ['librarian-puppet']

  s.add_dependency "thor", "~> 0.15"

end
