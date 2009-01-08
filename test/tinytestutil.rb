require 'tinytest/util'
require 'pathname'
require 'yaml'

module TinyTestUtil
  # parse file content below `__END__' lines (= DATA)
  # as YAML.
  def self.load_data(__file__)
    data = []
    in_data = false
    File.foreach(__file__) do |line|
      data << line if in_data
      in_data = true if /\A__END__\Z/ =~ line
    end
    YAML.load(data.join("\n"))
  end
  
  begin
    require 'win32ole'
    on_win_p = true
  rescue LoadError
    on_win_p = false
  end
  
  # file path comparer
  unless on_win_p
    def self.compare(x, y)
      x == y
    end
  else
    def self.compare(x, y)
      x.downcase == y.downcase
    end
  end
  
  # expand backtrace
  if Pathname.new(TinyTest::Util::TINY_DIR).relative?
    def self.expand(paths)
      paths
    end
  else
    def self.expand(paths)
      fname = File.expand_path(caller[0].sub(/:\d+(:in .*)?\Z/, ''))
      pwd = Dir.pwd
      begin
        Dir.chdir '..' if compare(pwd, File.dirname(fname))
        paths.map{|s| /\A\./ =~ s ? File.expand_path(s) : s }
      ensure
        Dir.chdir pwd
      end
    end
  end
  
  # in block, Time.now returns the same time.
  def self.time_stopper
    sc = (class << Time ; self ; end)
    t = stopped_time
    org = Time.method(:now)
    begin
      sc.class_eval{ define_method(:now){ t } }
      yield
    ensure
      sc.class_eval{ define_method(:now, org) }
    end
  end
  
  def self.stopped_time
    @stopped_time ||= Time.now
  end
  private_class_method :stopped_time
  
  stopped_time
end
