
#
# This is an extremely simple file that can consume
# a Puppet file with git references
#
# It does absolutely no dependency resolution by design.
#
require 'librarian/puppet/simple/installer'
require 'fileutils'

module Librarian
  module Puppet
    module Simple
      class CLI < Thor

        include Librarian::Puppet::Simple::Installer

        def self.bin!
          start
        end

        desc 'install', 'installs all git sources from your Puppetfile'
        method_options :verbose => :boolean, :clean => :boolean, :path => :string, :default => false
        def install
          @verbose = options[:verbose]
          clean if options[:clean]
          @custom_module_path = options[:path] 
          eval(File.read(File.join(base_dir, 'Puppetfile')))
        end
        
        desc 'clean', 'clean modules directory'
        method_options :path => :string, :default => false
        def clean
          target_directory = options[:path] || File.expand_path("./modules")
          puts "Target Directory: #{target_directory}" if @verbose
          FileUtils.rm_rf target_directory
        end
      end
    end
  end
end
