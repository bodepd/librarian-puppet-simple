require 'fileutils'
require 'rubygems/package'
require 'zlib'
require 'open-uri'

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
            if @custom_module_path
              @module_path = File.expand_path @custom_module_path
            else
              @module_path = File.join(dir, 'modules')
            end
            Dir.mkdir(@module_path) unless File.exists?(@module_path)
          end
          @module_path
        end

        def system_cmd (cmd)
          print_verbose "Running cmd: #{cmd}"
          output = `#{cmd}`.split("\n")
          print_verbose output
          raise(StandardError, "Cmd #{cmd} failed") unless $?.success?
          output
        end

        def mod(name, options = {})   
          # We get the last part of the module name
          # For example:
          #   puppetlabs/ntp  results in ntp 
          #   ntp             results in ntp 
          module_name = name.split('/', 2).last

          print_verbose "\n##### processing module #{name}..."

          case
          when options[:git]
            install_git module_path, module_name, options[:git], options[:ref]
          when options[:tarball]
            install_tarball module_path, module_name, options[:tarball]
          else
            abort('only the :git and :tarball provider are currently supported')
          end
        end

        private

        def install_git(module_path, module_name, repo, ref = nil)
          module_dir = File.join(module_path, module_name)

          Dir.chdir(module_path) do
            print_verbose "cloning #{repo}"
            system_cmd("git clone #{repo} #{module_name}")
            Dir.chdir(module_dir) do
              system_cmd('git branch -r')
              system_cmd("git checkout #{ref}") if ref
            end
          end
        end

        def install_tarball(module_path, module_name, remote_tarball)
          Dir.mktmpdir do |tmp|
            temp_file = File.join(tmp,"downloaded_module.tar.gz")
            File.open(temp_file, "w+b") do |saved_file|
              print_verbose "Downloading #{remote_tarball}..."
              open(remote_tarball, 'rb') do |read_file|
                saved_file.write(read_file.read)
              end
              saved_file.rewind

              target_directory = File.join(module_path, module_name)
              print_verbose "Extracting #{remote_tarball} to #{target_directory}..."
              unzipped_target = ungzip(saved_file)
              tarfile_full_name = untar(unzipped_target, module_path)
              FileUtils.mv File.join(module_path, tarfile_full_name), target_directory
            end
          end
        end

        def print_verbose(text)
          puts text if @verbose
        end

        # un-gzips the given IO, returning the
        # decompressed version as a StringIO
        def ungzip(tarfile)
          z = Zlib::GzipReader.new(tarfile)
          unzipped = StringIO.new(z.read)
          z.close
          unzipped
        end

        # untars the given IO into the specified
        # directory
        def untar(io, destination)
          tarfile_full_name = nil
          Gem::Package::TarReader.new io do |tar|
            tar.each do |tarfile|
              tarfile_full_name ||= tarfile.full_name
              destination_file = File.join destination, tarfile.full_name
              if tarfile.directory?
                FileUtils.mkdir_p destination_file
              else
                destination_directory = File.dirname(destination_file)
                FileUtils.mkdir_p destination_directory unless File.directory?(destination_directory)
                File.open destination_file, "wb" do |f|
                  f.print tarfile.read
                end
              end
            end
          end
          tarfile_full_name
        end
      end
    end
  end
end
