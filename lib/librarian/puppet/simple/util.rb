#
# this module contains all of the base helper methods
# used by the other actions
#
module Librarian
  module Puppet
    module Simple
      module Util

        def forge(repo)
          # this does nothing atm
        end
        # figure out what directory we are working out of
        def base_dir
          @base_dir ||= Dir.pwd
        end

        # figure out what the modulepath is
        def module_path(dir=base_dir)
          unless @module_path
            if @custom_module_path
              @module_path = File.expand_path @custom_module_path
            else
              @module_path = File.join(dir, 'modules')
            end
            Dir.mkdir(@module_path) unless File.exists?(@module_path)
          end
          @module_path
        end

        # run a command on the system
        def system_cmd (cmd, print_output=false)
          print_verbose "Running cmd: #{cmd}"
          output = `#{cmd}`.split("\n")
          if print_output
            puts output
          else
            print_verbose output
          end
          raise(StandardError, "Cmd #{cmd} failed") unless $?.success?
          output
        end

        def print_verbose(text)
          puts text if @verbose
        end

      end
    end
  end
end
