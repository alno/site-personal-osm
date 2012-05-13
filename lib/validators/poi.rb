module Validators
  module Poi

    def validate!
      nodes = DB[:nodes].select(:id, :tags, :geom).use_cursor
      ways = DB[:ways].select(:id, :tags).select_append{coalesce(st_buildarea(linestring), linestring).as(:geom)}.use_cursor

      # Shops without opening_hours

      nodes.where("(tags->'shop') IS NOT NULL AND (tags->'opening_hours') IS NULL").each do |r|
        save error_data('shop_without_opening_hours', 'node', r)
      end

      ways.where("(tags->'shop') IS NOT NULL AND (tags->'opening_hours') IS NULL").each do |r|
        save error_data('shop_without_opening_hours', 'way', r)
      end

      # Shops without name

      nodes.where("(tags->'shop') IS NOT NULL AND (tags->'name') IS NULL").each do |r|
        save error_data('shop_without_name', 'node', r)
      end

      ways.where("(tags->'shop') IS NOT NULL AND (tags->'name') IS NULL").each do |r|
        save error_data('shop_without_name', 'way', r)
      end
    end

    def error_data(err_type, obj_type, r)
      { :type => err_type, :source => 'pois', :source_id => r[:id].to_s, :geometry => r[:geom], :objects => ["#{obj_type}/#{r[:id]}"].pg_array, :params => {:name => r[:tags]['name']}.hstore, :updated_at => Time.now, :deleted_at => nil }
    end

    def save(data)
      if DB[:map_errors].where(:source => data[:source], :source_id => data[:source_id]).empty?
        DB[:map_errors].insert data.merge(:created_at => Time.now)
      else
        DB[:map_errors].where(:source => data[:source], :source_id => data[:source_id]).update data
      end
    end

    extend self
  end
end
