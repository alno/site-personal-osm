module Importers
  class Base

    class << self

      def global_db
        if defined? DB
          DB
        else
          nil
        end
      end

    end

    def initialize source, db, time = nil
      @source = source.to_s
      @db = db
      @time = time || Time.now

      if db
        puts "Saving imported data to #{db}"
      else
        puts "No DB defined, just dumping results"
      end
    end

    private

    def geojson_to_wkt geojson
      if geojson['type'] == 'Point'
        "POINT(#{geojson['coordinates'].reverse.join(' ')})"
      else
        raise StandardError.new("Unknown geojson type: '#{geojson['type']}'")
      end
    end

    def save_error! err
      err[:source] = @source
      err[:source_id] = Digest::SHA2.hexdigest "#{err[:types]}|#{err[:geometry]}"

      err[:updated_at] = @time
      err[:deleted_at] = nil

      if @db
        err[:params] = err[:params].hstore
        err[:types] = err[:types].pg_array

        if @db[:map_errors].where(:source => err[:source], :source_id => err[:source_id]).empty?
          err[:created_at] = Time.now

          @db[:map_errors].insert err
        else
          @db[:map_errors].where(:source => err[:source], :source_id => err[:source_id]).update err
        end
      else
        puts err.inspect
      end
    end

  end
end
