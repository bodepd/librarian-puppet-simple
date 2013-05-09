require 'librarian/puppet/simple/util'

module Librarian
  module Puppet
    module Simple
      module Iterator

        # evaluate a module and add it our @modules instance variable
        def mod(name, options = {})
          @modules ||= {}
          module_name = name.split('/', 2).last

          case
          when options[:git]
            @modules[:git] ||= []
            @modules[:git].push(options.merge(:name => module_name))
          when options[:tarball]
            @modules[:tarball] ||= []
            @modules[:tarball].push(options.merge(:name => module_name))
          else
            abort('only the :git and :tarball providers are currently supported')
          end
        end

        # iterate through all modules
        def each_module(&block)
          (@modules || {}).each do |type, repos|
            (repos || []).each do |repo|
              yield repo
            end
          end
        end

        # loop over each module of a certain type
        def each_module_of_type(type, &block)
          abort("undefined type #{type}") unless [:git, :tarball].include?(type)
          ((@modules || {})[type] || []).each do |repo|
            yield repo
          end
        end

      end
    end
  end
end
