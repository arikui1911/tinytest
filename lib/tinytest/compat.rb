unless Method.method_defined?(:source_location)
  class TinyTest::TestCase
    def self.method_added(name)
      filename, lineno = caller[0].match(TinyTest::Suite::CALLER_RE).captures
      lineno = Integer(lineno)
      TinyTest::Suite::METHOD_ADDED_RECORDS[[self, name]] = [filename, lineno]
    end
    private_class_method :method_added
  end
  
  class TinyTest::Suite
    METHOD_ADDED_RECORDS = {}
    
    def method_location(obj, name)
      METHOD_ADDED_RECORDS[[obj.class, name]]
    end
  end
end

unless Object.method_defined?(:define_singleton_method)
  class TinyTest::TestCase
    def bind_testsuite(suite)
      (class << self ; self ; end).class_eval{ define_method(:suite){ suite } }
    end
  end
end

