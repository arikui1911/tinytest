require 'test/unit'
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'tinytest/unit'
require 'tinytest/testrunner'

class TC_unit < Test::Unit::TestCase
  def test_attr_testrunner_autoinit
    TinyTest::Unit.testrunner = nil
    assert_instance_of TinyTest::TestRunner, TinyTest::Unit.testrunner
  end
  
  def test_autorun
    runner = Object.new
    def runner.run(args) ; 0 ; end
    hook = TinyTest::Unit.autorun
    assert_instance_of Proc, hook
    assert_same hook, TinyTest::Unit.autorun
    TinyTest::Unit.testrunner = runner
    at_exit{ TinyTest::Unit.testrunner = runner }
    TinyTest::Unit.autorun.call
  end
end
