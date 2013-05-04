module ActiveRecord
  module QueryMethods
    attr_accessor :calculon_opts
  end

  class Relation
    def to_buckets
      if(calculon_opts.nil?)
        raise "Not a Calculon Relation: You must call by_day/by_hour/etc before you can call to_buckets"
      end
      Calculon::Results.create(self)
    end
  end
end
