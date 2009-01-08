# 
# Distributes under The modified BSD license.
# 
# Copyright (c) 2009 arikui <http://d.hatena.ne.jp/arikui/>
# All rights reserved.
# 

module TinyTest
  # Exception which express assertion.
  # 
  class Assertion < Exception
    # Say report about not-succeeded test to TestRunner.
    #
    def disorder_report(testcase, testname)
      report = [
        disorder_type,
        "#{testname}(#{testcase.class}) [#{location(testcase)}]",
        message,
      ]
      report = report.join(":\n")
      report << "\n"
      report
    end
    
    private
    
    def location(testcase)
      hit = backtrace.find{|b| not testcase.refer_to_assertion?(b) }
      hit ||= backtrace.last
      hit.sub(/:in .*\z/, '')
    end
    
    def disorder_type
      'Failure'
    end
  end
  
  # Exception which express skipping.
  #
  class Skip < Assertion
    private
    def disorder_type
      'Skipped'
    end
  end
end
