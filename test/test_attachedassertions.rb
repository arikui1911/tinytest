require 'test/unit'
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'tinytest/assertions'
require 'tinytest/attachedassertions'

class TC_attachedassertions < Test::Unit::TestCase
  def teardown
    teardown_depend_hidden_AttachedAssertions_implement
  end
  
  def teardown_depend_hidden_AttachedAssertions_implement
    TinyTest::AttachedAssertions.module_eval{ include_table.clear }
  end
  
  def test_customed_include_depend_hidden_AttachedAssertions_implement
    modules = Array.new(rand(6)){|i|
      Module.new.instance_eval{
        @index = i
        def index ; @index ; end
        self
      }
    }
    assert_equal TinyTest::AttachedAssertions.module_eval{
      include(*modules)
      include_table
    }.keys.sort_by{|m| m.index }, modules
  end
  
  def test_own_def_directly_to_attachedassertions
    TinyTest::AttachedAssertions.module_eval{ def assert_hoge ; end }
    meth = TinyTest::AttachedAssertions.instance_method(:assert_hoge)
    assert TinyTest::AttachedAssertions.own?(meth)
  ensure
    TinyTest::AttachedAssertions.module_eval{ remove_method :assert_hoge }
  end
  
  def test_own_def_to_module_and_include
    mod = Module.new{ def assert_foo ; end }
    TinyTest::AttachedAssertions.module_eval{ include mod }
    assert TinyTest::AttachedAssertions.own?(mod.instance_method(:assert_foo))
  end
  
  def test_own_unrelated_method
    mod = Module.new{ def assert? ; end }
    assert !TinyTest::AttachedAssertions.own?(mod.instance_method(:assert?))
  end
  
  class TestReferToAssertion
    def initialize
      extend TinyTest::Assertions
      extend TinyTest::AttachedAssertions
    end
  end
  
  def test_refer_to_assertion
    o = TestReferToAssertion.new
    assert !o.refer_to_assertion?('misc/hoge.rb:666')
    assert !o.refer_to_assertion?("misc/piyo.rb:444:in `foobar'")
    assert !o.refer_to_assertion?("lib/tinytest/testcase.rb:in `setup'")
    assert  o.refer_to_assertion?("lib/tinytest/assertions.rb:in `assert_equal'")
  end
  
  def test_refer_to_assertion_about_added_assertion
    TinyTest::AttachedAssertions.module_eval do
      include Module.new{ def assert_foobar ; end }
    end
    o = TestReferToAssertion.new
    assert o.refer_to_assertion?("lib/tinytest/assertions.rb:in `assert_foobar'")
  end
  
  
end
