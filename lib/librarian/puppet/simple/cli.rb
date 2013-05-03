require 'librarian/puppet/simple/installer'
require 'fileutils'

module Librarian
  module Puppet
    module Simple
      class CLI < Thor
        include Librarian::Puppet::Simple::Installer

        class_option :verbose, :type => :boolean,
                     :desc => 'verbose output for executed commands'

        class_option :path, :type => :string,
                     :desc => "overrides target directory, default is ./modules"

        def self.bin!
          start
        end

        desc 'install', 'installs all git sources from your Puppetfile'
        method_option :clean, :type => :boolean, :desc => "calls clean before executing install"
        def install
          @verbose = options[:verbose]
          clean if options[:clean]
          @custom_module_path = options[:path] 
          eval(File.read(File.join(base_dir, 'Puppetfile')))
        end
        
        desc 'clean', 'clean modules directory'
        def clean
          target_directory = options[:path] || File.expand_path("./modules")
          puts "Target Directory: #{target_directory}" if @verbose
          FileUtils.rm_rf target_directory
        end
      end
    end
  end
end
