require 'set'

module Calculon
  class Results < Hash
    attr_reader :rows

    def initialize(relation)
      super({})

      @bucket_size = relation.calculon_opts[:bybucket]
      @grouped_by = relation.calculon_opts[:group_by] || []
      @grouped_by_values = Set.new

      @start_time = relation.calculon_opts[:starttime] || keys.sort.first
      @start_time = @start_time.to_time if @start_time.is_a?(Date)

      @end_time = relation.calculon_opts[:endtime] || keys.sort.last
      @end_time = @end_time.to_time if @end_time.is_a?(Date)

      relation.to_a.each { |row|
        # Keep track of all of the unique column values for the group_by cols
        @grouped_by_values.add @grouped_by.inject({}) { |h,col| h[col] = row.send(col); h }
        self[row.time_bucket] = fetch(row.time_bucket, []) + [ row ]
      }
    end

    def self.create(relation)
      if (relation.calculon_opts[:group_by] || []).length > 0
        MultiGroupingResults.new(relation)
      else
        SingleGroupingResults.new(relation)
      end
    end

    def groupings
      @grouped_by_values.to_a
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

    def map_each_time
      increment_amounts = { :minute => 1.minute, :hour => 1.hour, :day => 1.day, :month => 1.month, :year => 1.year }
      increment = increment_amounts[@bucket_size]

      # get the "floor" of the start and end times (the "floor" bucket)
      current = Time.zone.parse(@start_time.strftime(time_format + " %z"))
      last_time = Time.zone.parse(@end_time.strftime(time_format + " %z"))

      results = []
      while current <= last_time
        results << yield(current.strftime(time_format))
        current += increment
      end
      results
    end
  end

  class SingleGroupingResults < Results
    def to_a(default=nil)
      map_each_time { |key|
        fetch(key, [default]).first
      }
    end
  end

  class MultiGroupingResults < Results
    def to_a
      map_each_time { |key|
        fetch(key, [])
      }
    end

    def values_for(grouping, default=nil)
      map_each_time { |key|
        matches = fetch(key, []).select { |value| grouping.map { |k,v| value.send(k) == v }.all? }
        matches.length > 0 ? matches.first : default
      }
    end
  end
end
