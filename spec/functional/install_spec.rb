require 'spec_helper'

require 'tmpdir'

describe "Functional - Install" do
  before :all do
    warning_message = "ATTENTION: these tests download information from github.com and forge.puppetlabs.com"
    puts '*' * warning_message.length
    puts warning_message
    puts '*' * warning_message.length
  end

  it "displays install help message" do
    output, status = execute_captured("bin/librarian-puppet help install")
    output.should_not include("ERROR")
    output.should_not include("Could not find command")
    status.should == 0
  end

  describe "when running 'librarian-puppet install'" do
    temp_directory = nil

    before :each do
      temp_directory = Dir.mktmpdir
      Dir.entries(temp_directory).should =~ %w|. ..|
      FileUtils.touch File.join(temp_directory, 'trashfile')
      Dir.entries(temp_directory).should =~ %w|. .. trashfile|
    end

    after :each do
      FileUtils.rm_rf temp_directory
    end

    it "install the modules in a temp directory", :type => 'integration' do
      output, status = execute_captured("bin/librarian-puppet install --path=#{temp_directory} --puppetfile=spec/fixtures/Puppetfile")

      status.should == 0
      Dir.entries(temp_directory).should =~ %w|. .. apache ntp trashfile dnsclient testlps subdir-A|
      Dir.entries(File.join(temp_directory, 'subdir-A')).should =~ %w|. .. .git Hello.txt|
    end

    

    it "with --clean it cleans the directory before installing the modules in a temp directory", :type => 'integration' do
      output, status = execute_captured("bin/librarian-puppet install --clean --path=#{temp_directory} --puppetfile=spec/fixtures/Puppetfile")

      status.should == 0
      Dir.entries(temp_directory).should =~ %w|. .. apache ntp dnsclient testlps subdir-A|
    end

    it "with --verbose it outputs progress messages", :type => 'integration' do
      output, status = execute_captured("bin/librarian-puppet install --verbose --path=#{temp_directory} --puppetfile=spec/fixtures/Puppetfile")

      status.should == 0
      output.should include('##### processing module apache')
    end

    describe 'when modules are already installed' do
      temp_directory = nil

      before :each do
        temp_directory = Dir.mktmpdir
        Dir.entries(temp_directory).should =~ %w|. ..|
        FileUtils.touch File.join(temp_directory, 'apache')
        Dir.entries(temp_directory).should =~ %w|. .. apache|
      end

      it 'without clean it should only install ntp', :type => 'integration' do
        output, status = execute_captured("bin/librarian-puppet install --verbose --path=#{temp_directory} --puppetfile=spec/fixtures/Puppetfile")
        status.should == 0
        output.should include('Module apache already installed')
        Dir.entries(temp_directory).should =~ %w|. .. apache ntp dnsclient testlps subdir-A|
      end
    end
  end

end
