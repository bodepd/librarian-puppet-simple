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

        def system_cmd (cmd, print=@verbose)
          puts "Running cmd: #{cmd}" if print
          output = `#{cmd}`.split("\n")
          puts output.join("\n") if print
          raise(StandardError, "Cmd #{cmd} failed") unless $?.success?
          output
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

        def mod(name, options = {})   
          # We get the last part of the module name
          # For example:
          #   puppetlabs/ntp  results in ntp 
          #   ntp             results in ntp 
          module_name = name.split('/', 2).last

          module_dir = File.join(module_path, module_name)
          case
          when options[:git]
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
          when options[:tarball]
            remote_target = options[:tarball]
            Dir.mktmpdir do |tmp|
              local_target = File.join(tmp,"downloaded_module.tar.gz")
              File.open(local_target, "w+b") do |saved_file|
                open(remote_target, 'rb') do |read_file|
                  saved_file.write(read_file.read)
                end
                saved_file.rewind
                unzipped_target = ungzip(saved_file)
                tarfile_full_name = untar(unzipped_target, module_path)
                FileUtils.mv File.join(module_path, tarfile_full_name), File.join(module_path, module_name)
              end
            end
          else
            abort('only the :git and :tarball provider are currently supported')
          end

        end
      end
    end
  end
end
