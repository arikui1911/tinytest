require 'test/unit'
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'tinytest/exceptions'

class TC_exceptions < Test::Unit::TestCase
  class TestCase
    def self.to_s
      'TESTCASE'
    end
    
    def refer_to_assertion?(str)
      /\Aassertion/ === str
    end
  end
  
  def lines(*args)
    args.join("\n") << "\n"
  end
  
  BackTrace = [
    "assertion:in `hoge'",
    "assertion",
    "not assertion:in `piyo'",
  ]
  
  def test_assertion
    ex = TinyTest::Assertion.new('MESSAGE')
    ex.set_backtrace BackTrace
    testcase = TestCase.new
    assert_equal lines(
      "Failure:",
      "TESTNAME(TESTCASE) [not assertion]:",
      "MESSAGE"
    ), ex.disorder_report(testcase, 'TESTNAME')
  end
  
  def test_skip
    ex = TinyTest::Skip.new('MESSAGE')
    ex.set_backtrace BackTrace
    testcase = TestCase.new
    assert_equal lines(
      "Skipped:",
      "TESTNAME(TESTCASE) [not assertion]:",
      "MESSAGE"
    ), ex.disorder_report(testcase, 'TESTNAME')
  end
end
