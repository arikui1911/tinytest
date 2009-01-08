# 
# Distributes under The modified BSD license.
# 
# Copyright (c) 2009 arikui <http://d.hatena.ne.jp/arikui/>
# All rights reserved.
# 

require 'tinytest/testrunner'
require 'tinytest/testcase'

# Manage ordinary TinyTest's running.
# 
module TinyTest::Unit
  TinyTest::TestCase.testcases_container_caller do
    self.testrunner.testcases
  end
  
  # Readable attribute.
  # But be refered without assignning beforehand, this attribute
  # initialized as TinyTest::TestRunner object.
  # 
  def self.testrunner
    @testrunner ||= TinyTest::TestRunner.new
  end
  
  # Writable attribute.
  # 
  def self.testrunner=(runner)
    @testrunner = runner
  end
  
  # A first time to be called, add hook to run tests at exit.
  # Returns a callback Proc for the hook.
  # -> Proc
  # 
  def self.autorun
    @autorunner ||= add_hock_at_exit()
  end
  
  def self.add_hock_at_exit
    at_exit do
      status = testrunner.run(ARGV)
      exit false if status && status != 0
    end
  end
  private_class_method :add_hock_at_exit
end
