desc 'Validate files'
task :validate do
  Dir[
    'spec/**/*.rb',
    'lib/**/*.rb',
    'Gemfile',
    'bin/*',
    '*.gemspec',
  ].each do |ruby_file|
    sh "ruby -c #{ruby_file}" unless ruby_file =~ /spec\/fixtures\/modules/
  end
end

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
end

desc 'Run tests'
task :test do
  [:validate, :spec].each do |test|
    Rake::Task[test].invoke
  end
end
