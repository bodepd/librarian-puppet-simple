require 'librarian/puppet/simple/installer'
require 'librarian/puppet/simple/iterator'
require 'fileutils'

module Librarian
  module Puppet
    module Simple
      class CLI < Thor

        include Librarian::Puppet::Simple::Util
        include Librarian::Puppet::Simple::Installer
        include Librarian::Puppet::Simple::Iterator

        class_option :verbose, :type => :boolean,
                     :desc => 'verbose output for executed commands'

        class_option :path, :type => :string,
                     :desc => "overrides target directory, default is ./modules"
        class_option :puppetfile, :type => :string,
                     :desc => "overrides used Puppetfile",
                     :default => './Puppetfile'


        def self.bin!
          start
        end

        desc 'install', 'installs all git sources from your Puppetfile'
        method_option :clean, :type => :boolean, :desc => "calls clean before executing install"
        def install
          @verbose = options[:verbose]
          clean if options[:clean]
          @custom_module_path = options[:path]
          # evaluate the file to populate @modules
          eval(File.read(File.expand_path(options[:puppetfile])))
          install!
        end

        desc 'clean', 'clean modules directory'
        def clean
          target_directory = options[:path] || File.expand_path("./modules")
          puts "Target Directory: #{target_directory}" if options[:verbose]
          FileUtils.rm_rf target_directory
        end

        desc 'git_status', 'determine the current status of checked out git repos'
        def git_status
          @custom_module_path = options[:path]
          # populate @modules
          eval(File.read(File.expand_path(options[:puppetfile])))
          each_module_of_type(:git) do |repo|
            Dir.chdir(File.join(module_path, repo[:name])) do
              status = system_cmd('git status')
              if status.include?('nothing to commit (working directory clean)')
                puts "Module #{repo[:name]} has not changed" if options[:verbose]
              else
                puts "Uncommitted changes for: #{repo[:name]}"
                puts "  #{status.join("\n  ")}"
              end
            end
          end
        end

        desc 'dev_setup', 'adds development r/w remotes to each repo (assumes remote has the same name as current repo)'
        def dev_setup(remote_name)
          @custom_module_path = options[:path]
          # populate @modules
          eval(File.read(File.expand_path(options[:puppetfile])))
          each_module_of_type(:git) do |repo|
            Dir.chdir(File.join((options[:path] || 'modules'), repo[:name])) do
              print_verbose "Adding development remote for git repo #{repo[:name]}"
              remotes = system_cmd('git remote')
              if remotes.include?(remote_name)
                puts "Did not have to add remote #{remote_name} to #{repo[:name]}"
              elsif ! remotes.include?('origin')
                raise(TestException, "Repo #{repo[:name]} has no remote called origin, failing")
              else
                remote_url = system_cmd('git remote show origin').detect {|x| x =~ /\s+Push\s+URL: / }
                if remote_url =~ /(git|https?):\/\/(.+)\/(.+)?\/(.+)/
                  url = "git@#{$2}:#{remote_name}/#{$4}"
                  puts "Adding remote #{remote_name} as #{url}"
                  system_cmd("git remote add #{remote_name} #{url}")
                elsif remote_url =~ /^git@/
                  puts "Origin is already a read/write remote, skipping b/c this is unexpected"
                else
                  puts "remote_url #{remote_url} did not have the expected format. weird..."
                end
              end
            end
          end
        end

      end
    end
  end
end
