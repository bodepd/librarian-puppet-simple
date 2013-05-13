require 'spec_helper'

require 'tmpdir'

describe "Functional - Clean" do
  it "displays install help message" do
    output, status = execute_captured("bin/librarian-puppet help clean")
    output.should_not include("ERROR")
    output.should_not include("Could not find command")
    status.should == 0
  end

  describe "when running 'librarian-puppet clean'" do
    temp_directory = nil

    before :each do
      temp_directory = Dir.mktmpdir
      Dir.entries(temp_directory).should =~ ['.', '..']
      FileUtils.touch File.join(temp_directory, 'trashfile')
      Dir.entries(temp_directory).should =~ ['.', '..', 'trashfile']
    end

    after :each do
      FileUtils.rm_rf temp_directory if File.exist?(temp_directory)
    end

    it "with --path it cleans the directory" do
      output, status = execute_captured("bin/librarian-puppet clean --path=#{temp_directory}")

      status.should == 0
      # Using File.exist? to be compatible with Ruby 1.8.7
      File.exist?(temp_directory).should be_false
    end

    it "with --verbose it shows progress messages" do
      output, status = execute_captured("bin/librarian-puppet clean --verbose --path=#{temp_directory}")

      status.should == 0
      output.should include("Target Directory: #{temp_directory}")
    end
  end
end