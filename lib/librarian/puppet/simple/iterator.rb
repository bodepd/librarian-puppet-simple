require 'librarian/puppet/simple/util'

module Librarian
  module Puppet
    module Simple
      module Iterator

        # evaluate a module and add it our @modules instance variable
        def mod(name, options = {})
          @modules ||= {}
          full_name   = name
          module_name = name.split('/', 2).last

          case
          when options[:git]
            @modules[:git] ||= {}
            @modules[:git][module_name] = options.merge(:name => module_name, :full_name => full_name)
          when options[:tarball]
            @modules[:tarball] ||= {}
            @modules[:tarball][module_name] = options.merge(:name => module_name, :full_name => full_name)
          else
            @modules[:forge] ||= {}
            @modules[:forge][module_name] = options.merge(:name => module_name, :full_name => full_name)
            #abort('only the :git and :tarball providers are currently supported')
          end
        end

        def modules
          @modules
        end

        def clear_modules
          @modules = nil
        end

        # iterate through all modules
        def each_module(&block)
          (@modules || {}).each do |type, repos|
            (repos || {}).values.each do |repo|
              yield repo
            end
          end
        end

        # loop over each module of a certain type
        def each_module_of_type(type, &block)
          abort("undefined type #{type}") unless [:git, :tarball].include?(type)
          ((@modules || {})[type] || {}).values.each do |repo|
            yield repo
          end
        end

      end
    end
  end
end
