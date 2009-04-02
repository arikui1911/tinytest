require 'rake/testtask'
task 'default' => 'test'
Rake::TestTask.new

require 'rake/rdoctask'
Rake::RDocTask.new do |t|
  t.rdoc_dir = 'doc'
  t.rdoc_files = FileList["lib/**/*.rb"].include("README")
  t.options.push '-S', '-N'
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new
rescue LoadError
end

