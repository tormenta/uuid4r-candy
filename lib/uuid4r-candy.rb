require 'uuid4r'

module UUID
  GREGORIAN_EPOCH_OFFSET = 0x01B2_1DD2_1381_4000 # Oct 15, 1582
  VARIANT = 0b1000_0000_0000_0000

  # Will accept :str, :bin, :txt
  module TemplateUUID4R
    def to_s
      self.export(:str)
    end
    def to_b
      self.export(:bin)
    end
    def to_txt
      self.export(:txt)
    end
  end

  class V1 < UUID4R::UUID4Rv1
    include TemplateUUID4R
    def to_time
      UUID.time(self)
    end
    def to_mac
      UUID.mac(self)
    end
    def clock_low_seq
      UUID.clock_low_seq(self)
    end
    alias :random :clock_low_seq
  end
  class TimeStamp < V1 ; end

  class V3 < UUID4R::UUID4Rv3
    include TemplateUUID4R
  end
  class MD5 < V3 ; end

  class V4 < UUID4R::UUID4Rv4
    include TemplateUUID4R
  end
  class Random < V4 ; end

  class V5 < UUID4R::UUID4Rv5
    include TemplateUUID4R
  end
  class SHA < V5 ; end

  def self.normalize(uuid)
    case uuid
    when String
      p [ uuid, uuid.size ]
      case uuid.size
      when 16
        uuid = UUID4R::import(:bin, uuid)
      when 32
        uuid  = UUID4R::import(:str, uuid)
      else
        raise "Invalid import format"
      end
    else
      uuid
    end 
  end

  # Most of the credit goes to https://github.com/ryanking/simple_uuid
  def self.time(uuid)
    uuid = self.normalize(uuid)
    return uuid if uuid.nil?
    bin = (uuid.respond_to? :to_b) ? uuid.to_b : uuid.export(:bin)
    elements = bin.unpack("Nnn")
    usecs = (elements[0] + (elements[1] << 32) + ((elements[2] & 0x0FFF) << 48) - GREGORIAN_EPOCH_OFFSET) / 10
    Time.at( usecs / 1_000_000, usecs % 1_000_000 )
  end

  def self.mac(uuid)
    uuid = self.normalize(uuid)
    return uuid if uuid.nil?
    bin = (uuid.respond_to? :to_b) ? uuid.to_b : uuid.export(:bin)
    '%02x:%02x:%02x:%02x:%02x:%02x' % bin.unpack('QnCCCCCC')[2..-1]
  end

  def self.clock_low_seq(uuid)
    uuid = self.normalize(uuid)
    return uuid if uuid.nil?
    bin = (uuid.respond_to? :to_b) ? uuid.to_b : uuid.export(:bin)
    bin.unpack('QCC')[2]
  end

  # Most of the credit goes to https://github.com/ryanking/simple_uuid
  def self.variant(uuid)
    uuid = self.normalize(uuid)
    bin = (uuid.respond_to? :to_b) ? uuid.to_b : uuid.export(:bin)
    bin.unpack('QnnN')[1] >> 13
  end

  def self.v1
    V1.new
  end

  def self.timestamp
    TimeStamp.new
  end

  def self.v3(ns, n)
    V3.new(ns, n)
  end

  def self.md5(ns, n)
    MD5.new(ns, n)
  end

  def self.v4
    V4.new
  end

  def self.random
    Random.new
  end

  def self.v5(ns, n)
    V5.new(ns, n)
  end

  def self.sha(ns, n)
    SHA.new(ns, n)
  end

end

if $0 == __FILE__

t = UUID.sha("ns:DNS", "HOOL")
p "SHA: #{t}"
s = UUID::TimeStamp.new
p "TIME: #{s}"
p [ :compare , t <=> s ]


tt = UUID.time(t)
st = UUID.time(s)
p [ :time , tt, st, tt.usec, st.usec , tt <=> st, st <=> tt , st < tt]
p [ s.to_mac, s.clock_low_seq, '%02x' % s.clock_low_seq ]
p UUID.variant(t)

require 'benchmark'

n = 100000
Benchmark.bm(7) do |x|
  t = nil

  x.report("create TimeStamp") {
    n.times {
      t = UUID::TimeStamp.new
    }
  }
  x.report("str_export") { 
    n.times { 
      t.to_s
    }
  }
  x.report("clock_low_seq") {
    n.times {
      t.clock_low_seq
    }
  }
  x.report("to_mac") {
    n.times {
      t.to_mac
    }
  }

end
end
