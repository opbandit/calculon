require "calculon/version"
require 'calculon/railtie'
require 'calculon/summarized_results'

module ActiveRecord
  module QueryMethods
    attr_accessor :calculon_opts
  end

  class Relation
    def to_results_hash
      if(calculon_opts.nil?)
        raise "Not a Calculon Relation: You must call by_day/by_hour/etc before you can call to_hash"
      end
      Calculon::SummarizedResults.new(self)
    end

    def to_filled_a(default=nil)
      to_results_hash.fill_missing!(default).to_a
    end
  end
end

module Calculon
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    def calculon_view(name, cols, opts=nil)
      metaclass = class << self; self; end
      metaclass.instance_eval do
        [ "minute", "hour", "day", "month", "year" ].each do |window|
          define_method("#{name}_by_#{window}") { |nopts=nil|
            nopts = (opts || {}).merge(nopts || {})
            send("by_#{window}".intern, cols, nopts)
          }
        end
      end
    end

    def default_time_column(column)
      @@calculon_time_column = column
    end

    def default_calculon_opts
      @@calculon_time_column ||= "created_at"
      { :time_column => @@calculon_time_column, :bycols => [] }
    end

    def on(date, opts=nil)
      opts = default_calculon_opts.merge(opts || {})
      raise "'on' method takes a Date object as the first param" unless date.is_a?(Date)
      relation = where ["#{opts[:time_column]} >= ? and #{opts[:time_column]} < ?", date.to_time, (date + 1.day).to_time]
      relation.calculon_opts ||= {}
      relation.calculon_opts.merge!(:starttime => date.to_time, :endtime => (date + 1.day).to_time)
      relation      
    end

    def between(starttime, endtime, opts=nil)
      opts = default_calculon_opts.merge(opts || {})
      relation = where ["#{opts[:time_column]} >= ? and #{opts[:time_column]} <= ?", starttime, endtime]
      relation.calculon_opts ||= {}
      relation.calculon_opts.merge!(:starttime => starttime, :endtime => endtime)
      relation
    end

    def by_minute(cols, opts=nil)
      tcol = "concat(date(%{time_column}),' ',lpad(hour(%{time_column}),2,'0'),':',lpad(minute(%{time_column}),2,'0'),':00')"
      by_bucket :minute, tcol, cols, opts
    end

    def by_hour(cols, opts=nil)
      by_bucket :hour, "concat(date(%{time_column}),' ',lpad(hour(%{time_column}),2,'0'),':00:00')", cols, opts
    end

    def by_day(cols, opts=nil)
      by_bucket :day, "concat(date(%{time_column}),' 00:00:00')", cols, opts
    end

    def by_month(cols, opts=nil)
      by_bucket :month, "concat(year(%{time_column}),'-',lpad(month(%{time_column}),2,'0'),'-01 00:00:00')", cols, opts
    end

    def by_year(cols, opts=nil)
      by_bucket :year, "concat(year(%{time_column}),'-01-01 00:00:00')", cols, opts
    end

    def by_bucket(bucket_name, bucket, cols, opts=nil)
      opts = default_calculon_opts.merge(opts || {})

      unless ActiveRecord::Base.connection.adapter_name == "Mysql2"
        raise "Mysql2 is the only supported connection adapter for calculon"
      end

      # Set column in bucket string.  This should be based on localtime, in case there are some points
      # that fall on both sides of a date - so group by this conversion.  The 'where' doesn't
      # need this conversion because Rails does this automatically before calling the query
      # (see http://api.rubyonrails.org/classes/ActiveRecord/Base.html#method-c-default_timezone)
      time_column = "CONVERT_TZ(#{opts[:time_column]}, '+00:00', '#{Time.zone.formatted_offset}')"
      bucket = bucket % { :time_column => time_column }

      # if we're grouping by other columns, we need to select them
      groupby = opts[:bycols] + ["time_bucket"]
      opts[:bycols].each { |c| cols[c] = nil }
      cols = cols.map { |name,method| 
        asname = name.to_s.gsub(' ', '').tr('^A-Za-z0-9', '_')
        method.nil? ? name : "#{method}(#{name}) as #{asname}" 
      } + [ "#{bucket} as time_bucket" ]

      relation = select(cols.join(",")).group(*groupby).order("time_bucket ASC")
      relation.calculon_opts ||= {}
      relation.calculon_opts.merge!(opts)
      relation.calculon_opts[:bybucket] = bucket_name
      relation
    end
  end
end
