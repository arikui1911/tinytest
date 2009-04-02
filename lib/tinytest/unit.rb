# 
# Distributes under The modified BSD license.
# 
# Copyright (c) 2009 arikui <http://d.hatena.ne.jp/arikui/>
# All rights reserved.
# 

require 'tinytest'
require 'optparse'

module TinyTest::Unit
  def self.autorun
    @autorunner ||= autorunner()
  end
  
  def self.autorun?
    @autorunner ? true : false
  end
  
  def self.autorunner
    @autorunner = at_exit{
      runner = parse_options(ARGV)
      runner.run
    }
  end
  private_class_method :autorunner
  
  def self.parse_options(argv)
    opts = {}
    o = OptionParser.new
    o.banner = "== TinyTest autorunner ==\n"
    o.banner << "Usage: test-script [options]\n"
    o.on('-n', '--testname=NAME', 'assign testname matcher') do |s|
      opts[:testname] = Regexp.new(s)
    end
    o.on('-t', '--testcase=NAME', 'assign testcase matcher') do |s|
      opts[:testcase] = Regexp.new(s)
    end
    o.on('-I', '--load-path=DIR', 'add to ruby load-path') do |s|
      $LOAD_PATH.push s
    end
    o.on('-v', '--[no-]verbose', 'turn on/off verbose mode') do |b|
      opts[:verbose] = b
    end
    o.parse! argv
    TinyTest::Runner.new(opts)
  end
  private_class_method :parse_options
end

