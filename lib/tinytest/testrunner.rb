# 
# Distributes under The modified BSD license.
# 
# Copyright (c) 2009 arikui <http://d.hatena.ne.jp/arikui/>
# All rights reserved.
# 

require 'tinytest/assertions'
require 'tinytest/attachedassertions'
require 'tinytest/testsuite'
require 'tinytest/exceptions'
require 'tinytest/util'
require 'optparse'

module TinyTest
  # ...
  class TestRunner
    # ...
    def initialize
      self.output = $stdout
      self.enable_attached_assertion = true
      @testcases = []
      @report    = []
      @skips     = []
      @failures  = []
      @errors    = []
      @exceptions = { Skip => @skips, Assertion => @failures }
      @exceptions.default = @errors
      @option_parser = create_option_parser()
    end
    
    attr_accessor :verbose,
                  :filter,
                  :enable_attached_assertion,
                  :output,
                  :n_tests,
                  :n_assertions
    attr_reader   :testcases,
                  :report,
                  :skips,
                  :failures,
                  :errors
    
    # ...
    def receive_disorder(testcase, testname, ex)
      @exceptions[ex.class] << [testcase, testname, ex]
      @report << report_about_disorder(testcase, testname, ex)
      @report.last[0, 1]
    end
    
    def report_about_disorder(testcase, testname, ex)
      if ex.respond_to?(:disorder_report)
        ex.disorder_report(testcase, testname)
      else
        msg = "Error:\n#{testname}(#{testcase}):\n#{ex.class}: #{ex.message}"
        msg = Util.filter_backtrace(ex.backtrace).unshift(msg).join("\n    ")
        msg << "\n"
        msg
      end
    end
    private :report_about_disorder
    
    # ...
    def run(args = [])
      @option_parser.parse! args
      out = Util::OutputProxy.new(output)
      out.puts "Loaded suite #{$0.sub(/\.rb\Z/, '')}\nStarted"
      t = Util.measure_time{ run_test_suites(out, self.filter) }
      out.printf "\nFinished in %.6f seconds.\n", t
      @report.each_with_index do |msg, i|
        out.printf "\n%3d) %s\n", i.succ, msg
      end
      out.puts if @report.empty?
      out.puts [ "#{n_tests} tests",
                 "#{n_assertions} assertions",
                 "#{failures.size} failures",
                 "#{errors.size} errors",
                 "#{skips.size} skips" ].join(', ')
      failures.size + errors.size if n_tests > 0
    end
    
    private
    
    def run_test_suites(out, filter = /./)
      filter ||= /./
      self.n_tests = self.n_assertions = 0
      out.escape_sync(true) do
        ready_test_suites(filter).each do |suite|
          self.n_tests += 1
          self.n_assertions += suite.count_assertions{
            out.print "#{suite.inspect}: " if verbose
            result = nil
            t = Util.measure_time{ result = suite.run(self) }
            out.printf "%.2f s: ", t if verbose
            out.print result
            out.puts if verbose
          }
        end
      end
      return n_tests, n_assertions
    end
    
    def ready_test_suites(filter)
      testcases.sort_by{|c| c.name }.inject([]){|suites, testcase|
        suites.concat testcase.collect_tests.grep(filter).map{|test|
          TestSuite.new(testcase, test) do |c|
            c.extend Assertions
            c.extend AttachedAssertions if enable_attached_assertion
          end
        }
      }
    end
    
    def create_option_parser
      o = OptionParser.new
      o.on('-v', '--[no-]verbose'){|b| @verbose = b }
      o.on('-n', '--name=NAME'){|s| @filter = s }
      o.on('-e', '--regexp=PAT'){|s| @filter = /#{s}/ }
      o
    end
  end
end
