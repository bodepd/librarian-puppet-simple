
#
# This is an extremely simple file that can consume
# a Puppet file with git references
#
# It does absolutely no dependency resolution by design.
#
require 'librarian/puppet/simple/installer'
module Librarian
  module Puppet
    module Simple
      class CLI < Thor

        include Librarian::Puppet::Simple::Installer

        def self.bin!
          start
        end

        desc 'install', 'installs all git sources from your Puppetfile'
        method_options :verbose => :boolean, :default => false
        def install
          @verbose = options[:verbose]
          eval(File.read(File.join(base_dir, 'Puppetfile')))
        end
      end
    end
  end
end
