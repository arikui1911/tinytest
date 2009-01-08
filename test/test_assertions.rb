# incomplete

require 'test/unit'
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'tinytest/assertions'
require 'tinytest/exceptions'

class TC_assertions < Test::Unit::TestCase
  def test_pass
    assert true
  end
end
