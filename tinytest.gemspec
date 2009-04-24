# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{tinytest}
  s.version = "0.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["arikui"]
  s.date = %q{2009-04-22}
  s.description = %q{TinyTest rips off minitest-1.3.1.  It is a simple testing library.}
  s.email = %q{arikui.ruby@gmail.com}
  s.extra_rdoc_files = ["README", "LICENSE"]
  s.files = ["README", "LICENSE", "Rakefile", "test/test_tinytest.rb", "lib/tinytest.rb", "lib/tinytest/compat.rb", "lib/tinytest/unit.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://wiki.github.com/arikui1911/tinytest}
  s.rdoc_options = ["--title", "tinytest documentation", "--charset", "utf-8", "--opname", "index.html", "--line-numbers", "--main", "README", "--inline-source", "--exclude", "^(examples|extras)/"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{tinytest}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{simple unit test library which rips off minitest}
  s.test_files = ["test/test_tinytest.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
