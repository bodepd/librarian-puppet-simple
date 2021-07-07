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

        desc 'update', 'updates all git sources from your Puppetfile'
        method_option :update, :type => :boolean, :desc => "Updates git sources"
        def update
          @verbose = options[:verbose]
          @custom_module_path = options[:path]
          eval(File.read(File.expand_path(options[:puppetfile])))
          each_module_of_type(:git) do |repo|
            if Dir.exists?(File.join(module_path, repo[:name]))
              Dir.chdir(File.join(module_path, repo[:name])) do
                remote = repo[:git]
                # if no ref is given, assume master
                branch = repo[:ref] || 'master'
                if branch =~ /^origin\/(.*)$/
                  branch = $1
                end
                co_cmd     = "git checkout #{branch}"
                update_cmd = "git fetch --all && #{co_cmd}"
                print_verbose "\n\n#{repo[:name]} -- #{update_cmd}"
                git_pull_cmd = system_cmd(update_cmd)
              end
            else
              install_git module_path, repo[:name], repo[:git], repo[:ref]
            end
          end
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

        #
        # I am not sure if anyone besides me (Dan Bode) should use this command.
        # It is specifically for the use case where you are managing downstream versions
        # of Puppet modules, where you want to track the relationship between your downstream
        # forks and upstream.
        # It required a specially formatted Puppetfile that expects an environment variable called
        # repo_to_use that accepts the values 'upstream' and 'downstream'. It should use that environment
        # variable to be able to generate either the upstream or downstream set of repos.
        #
        # Given those requirements, it can be used to compare the revision history differences betwee
        # those commits.
        #
        desc 'compare_repos', 'compares the specified upstream and downstream repos'
        method_option :output_file, :type => :string,
          :desc => "Name of Puppetfile to save the results as"
        method_option :ignore_merges, :type => :boolean,
          :desc => 'Indicates that merge commits should be ignored'
        method_option :show_diffs, :type => :boolean,
          :desc => 'Show code differences of divergent commits (add -u)'
        # I was really just using this for testing
        # not sure if end users need it
        method_option :existing_tmp_dir, :type => :string,
          :desc => 'Uses an existing directory. Assumes the downstream repos have already been populated.'
        method_option :upstream_only, :type => :boolean,
          :desc => 'Only show commits that are only in the upstream'
        method_option :downstream_only, :type => :boolean,
          :desc => 'Only show commits that are only in downstream'
        method_option :oneline, :type => :boolean,
          :desc => 'Condense log output to one line'


        def compare_repos

          repo_hash = {}
          @verbose            = options[:verbose]
          abort('path not supported by compare_repos command') if options[:path]
          if options[:downstream_only] and options[:upstream_only]
            abort('Cannot specify both downstream_only and upstream_only')
          end

          # create path where code will be stored
          if options[:existing_tmp_dir]
            path = options[:existing_tmp_dir]
          else
            path = File.join('.tmp', Time.now.strftime("%Y_%m_%d_%H_%S"))
          end

          FileUtils.mkdir_p(path)
          @custom_module_path = path

          # install the downstream modules in our tmp directory and build out a hash
          downstream = build_puppetfile_hash('downstream', !options[:existing_tmp_dir])
          # just build a hash of the downstream modules
          upstream   = build_puppetfile_hash('upstream', false)

          unless ( (downstream.keys - upstream.keys) == [] and
                   (upstream.keys - downstream.keys)
                 )
            abort('Your Puppetfile did not produce the same upstream and downstream repos, this is not yet supported')
          else

            upstream.each do |us_name, us_repo|
              # compare to see if the source of revisions are the same
              ds_repo = downstream[us_name]
              if ds_repo[:git] == us_repo[:git] and ds_repo[:ref] == us_repo[:ref]
                print_verbose("\nSources of #{us_name} are the same, nothing to compare.")
              else
                Dir.chdir(File.join(path, us_name)) do
                  if us_repo[:git] =~ /(git|https?):\/\/(.+)\/(.+)?\/(.+)/
                    remote_name = $3
                    remotes = system_cmd('git remote')
                    if remotes.include?(remote_name)
                      puts "Did not have to add remote #{remote_name} to #{us_repo[:name]}, it was already there"
                    else
                      puts "Adding remote #{remote_name} #{us_repo[:git]}"
                      system_cmd("git remote add #{remote_name} #{us_repo[:git]}")
                    end
                    system_cmd("git fetch #{remote_name}")
                    if us_repo[:ref] =~ /^origin\/(\S+)$/
                      compare_ref = "#{remote_name}/#{$1}"
                    else
                      compare_ref = "#{remote_name}/#{us_repo[:ref]}"
                    end

                    # set up parameters for git log call
                    ignore_merges = options[:ignore_merges] ? '--no-merges' : ''
                    show_diffs    = options[:show_diffs]    ? '-u' : ''
                    oneline       = options[:oneline]       ? '--oneline' : ''
                    # show the results, this assumes that HEAD is up-to-date (which it should be)

                    if options[:downstream_only] and options[:upstream_only]
                      abort('Cannot specify both downstream_only and upstream_only')
                    end
                    puts "########## Results for #{us_name} ##########"
                    unless options[:upstream_only]
                      puts "  ######## Commits only in downstream ########"
                      results = system_cmd("git log --left-only HEAD...#{compare_ref} #{ignore_merges} #{show_diffs} #{oneline}", true)
                      puts "  ######## End Downstream results ########"
                    end
                    unless options[:downstream_only]
                      puts "  ######## Commits only in upstream ########"
                      results = system_cmd("git log --right-only HEAD...#{compare_ref} #{ignore_merges} #{show_diffs} #{oneline}", true)
                      puts "  ######## End upstream ########"
                    end
                    puts "########## End of Results for #{us_name} ##########"
                  else
                    abort("Unrecognizable upstream url #{us_repo[:git]}")
                  end
                end
              end
            end
          end
        end

        desc 'generate_puppetfile', 'generates a static version of the Puppetfile'
        method_option :out_file,
          :desc => 'output file where static puppetfile should be written to'
        def generate_puppetfile
          eval(File.read(File.expand_path(options[:puppetfile])))
          if options[:out_file]
            File.open(options[:out_file], 'w') do |fh|
              print_puppet_file(fh)
            end
          else
            print_puppet_file(STDOUT)
          end
        end

        private

          def print_puppet_file(stream)
            each_module do |repo|
              repo.delete(:name)
              out_str = repo.delete(:full_name)
              repo.each do |k,v|
                out_str << ", :#{k} => #{v}"
              end
              stream.puts(out_str)
            end
          end

          # builds out a certain type of repo
          def build_puppetfile_hash(name, perform_installation=false)
            repo_hash = {}
            # set environment variable to determine what version of modules to install
            # this assumes that the environment variable repos_to_use has been coded in
            # your Puppetfile to allow installation of different versions of modules
            ENV['repos_to_use'] = name
            # parse Puppetfile and install modules in our tmp directory.
            eval(File.read(File.expand_path(options[:puppetfile])))
            # install modules if desired
            install! if perform_installation

            # iterate through all git modules
            each_module_of_type(:git) do |git_repo|
              abort("Module git_repo[:name] was defined multiple times in same Puppetfile") if repo_hash[git_repo[:name]]
              repo_hash[git_repo[:name]] = git_repo
            end
            # clear out the modules once finished
            clear_modules
            repo_hash
          end

      end
    end
  end
end
