require 'rake/testtask'
Rake::TestTask.new do |t|
  t.warning = true
end
task 'default' => 'test'

require 'rake/rdoctask'
Rake::RDocTask.new do |t|
  t.rdoc_dir = 'doc'
  t.rdoc_files = FileList["lib/**/*.rb"]
  t.options.push '-S', '-N'
  t.template = File.expand_path(
    File.join(File.dirname(__FILE__), 'misc', 'rdoctemplate.rb'))
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new
rescue LoadError
end
