require 'fileutils'
require 'rubygems/package'
require 'zlib'
require 'open-uri'
require 'librarian/puppet/simple/util'
require 'librarian/puppet/simple/iterator'

# This is an extremely simple file that can consume
# a Puppet file with git references
#
# It does absolutely no dependency resolution by design.
#
module Librarian
  module Puppet
    module Simple
      module Installer

        include Librarian::Puppet::Simple::Util
        include Librarian::Puppet::Simple::Iterator

        # installs modules using the each_module method from our
        # iterator mixin
        def install!
          each_module do |repo|

            print_verbose "\n##### processing module #{repo[:name]}..."

            module_dir = File.join(module_path, repo[:name])

            unless File.exists?(module_dir)
              case
              when repo[:git]
                install_git module_path, repo[:name], repo[:git], repo[:ref], repo[:path]
              when repo[:tarball]
                install_tarball module_path, repo[:name], repo[:tarball]
              else
                abort('only the :git and :tarball provider are currently supported')
              end
            else
              print_verbose "\nModule #{repo[:name]} already installed in #{module_path}"
            end
          end
        end

        private

        # installs sources that are git repos
        def install_git(module_path, module_name, repo, ref = nil, path = nil)
          module_dir = File.join(module_path, module_name)

          if path.nil?
            clone(module_name, repo)
            Dir.chdir(module_dir) do
              system_cmd('git branch -r')
              system_cmd("git checkout #{ref}") if ref
            end
          else
            sparse_checkout(module_dir, repo, ref, path)
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

        # clones the git repository into
        # the current path.
        def clone(module_name, repo)
          Dir.chdir(module_path) do
            print_verbose "cloning #{repo}"
            system_cmd("git clone #{repo} #{module_name}")
          end
        end

        # makes a sparse git checkout
        def sparse_checkout(module_dir, repo, ref, path)
          Dir.mkdir(module_dir)
          Dir.chdir(module_dir) do
            print_verbose "sparse checkout #{repo} #{path}"
            system_cmd("git init")
            system_cmd("git remote add -f origin #{repo}")
            system_cmd("git config core.sparsecheckout true")
            # do this using file io
            system_cmd("echo #{path} >> .git/info/sparse-checkout")
            system_cmd("git pull origin #{ref.nil? ? HEAD : ref}")
            system_cmd("mv #{path}/* . && rmdir -p #{path}")
          end
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
                  f.write tarfile.read
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
