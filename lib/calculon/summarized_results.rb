module Calculon
  class SummarizedResults < Hash
    attr_reader :rows

    def initialize(relation)
      super({})

      @bucket_size = relation.calculon_opts[:bybucket]
      @grouped_by = relation.calculon_opts[:bycols] || []

      @start_time = relation.calculon_opts[:starttime] || keys.sort.first
      @start_time = @start_time.to_time if @start_time.is_a?(Date)

      @end_time = relation.calculon_opts[:endtime] || keys.sort.last
      @end_time = @end_time.to_time if @end_time.is_a?(Date)

      relation.to_a.each { |row|
        self[row.time_bucket] = row
      }
    end
    
    def fill_missing!(value=nil)
      each_time { |key|
        self[key] = value unless has_key?(key)
      }
      self
    end

    def to_a
      results = []
      each_time { |key|
        results << self[key] if self.has_key?(key)
      }
      results
    end

    def time_format
      { 
        :minute => "%Y-%m-%d %H:%M:00", 
        :hour => "%Y-%m-%d %H:00:00", 
        :day => "%Y-%m-%d 00:00:00", 
        :month => "%Y-%m-01 00:00:00", 
        :year => "%Y-01-01 00:00:00"
      }.fetch(@bucket_size)
    end

    def each_time
      increment_amounts = { :minute => 1.minute, :hour => 1.hour, :day => 1.day, :month => 1.month, :year => 1.year }
      increment = increment_amounts[@bucket_size]

      # get the "floor" of the start and end times (the "floor" bucket)
      current = Time.zone.parse(@start_time.strftime(time_format + " %z"))
      last_time = Time.zone.parse(@end_time.strftime(time_format + " %z"))

      while current <= last_time
        yield current.strftime(time_format)
        current += increment
      end
    end
  end
end
