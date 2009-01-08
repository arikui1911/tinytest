require 'test/unit'
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'tinytest/testcase'

class TC_testcase < Test::Unit::TestCase
  def test_setup_default_implement
    assert_nothing_raised(NoMethodError){ TinyTest::TestCase.new.setup }
  end
  
  def test_teardown_default_implement
    assert_nothing_raised(NoMethodError){ TinyTest::TestCase.new.teardown }
  end
  
  def self.container
    @container ||= []
  end
  
  TinyTest::TestCase.testcases_container_caller{ container }
  
  class TestCaseSubClass < TinyTest::TestCase
    def test_hoge    ; end
    def test_piyo    ; end
    def not_test_foo ; end
  end
  
  def test_collect_tests
    assert_equal ['test_hoge', 'test_piyo'].sort,
                 TestCaseSubClass.collect_tests.sort
  end
  
  def test_testcase_inherited_hook
    buf = []
    TinyTest::TestCase.testcases_container_caller{ buf }
    klass = Class.new(TinyTest::TestCase)
    assert_equal 1, buf.size
    assert_same klass, buf.first
  ensure
    TinyTest::TestCase.testcases_container_caller{ TC_testcase.container }
  end
end
