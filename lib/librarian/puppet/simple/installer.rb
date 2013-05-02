require 'fileutils'
# This is an extremely simple file that can consume
# a Puppet file with git references
#
# It does absolutely no dependency resolution by design.
#
module Librarian
  module Puppet
    module Simple
      module Installer

        def base_dir
          @base_dir ||= Dir.pwd
        end

        def module_path(dir=base_dir)
          unless @module_path
            @module_path = File.join(dir, 'modules')
            Dir.mkdir(File.join(dir, 'modules')) unless File.exists?(@module_path)
          end
          @module_path
        end

        def system_cmd (cmd, print=@verbose)
          puts "Running cmd: #{cmd}" if print
          output = `#{cmd}`.split("\n")
          puts output.join("\n") if print
          raise(StandardError, "Cmd #{cmd} failed") unless $?.success?
          output
        end

        def mod(name, options = {})

          # assumes that all modulenames are of the form
          # module_namespace/module_name
          module_name = name.split('/', 2)[1]

          module_dir = File.join(module_path, module_name)

          if options[:git]

            Dir.chdir(module_path) do
              puts "cloning #{options[:git]}" if @verbose
              system_cmd("git clone #{options[:git]} #{module_name}")
              Dir.chdir(module_dir) do
                system_cmd('git branch -r') if @verbose
                if options[:ref]
                  system_cmd("git checkout #{options[:ref]}")
                end
              end
            end

          else
            abort('only the :git provider is currently supported')
          end

        end
      end
    end
  end
end
