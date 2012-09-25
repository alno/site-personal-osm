require 'ox'

module Importers
  module Zkir

    class Handler < ::Ox::Sax

      ERROR_STACKS = {
        [:QualityReport, :AddressTest, :CitiesWithoutPopulation, :City] => :city_without_population,
        [:QualityReport, :AddressTest, :CitiesWithoutPlacePolygon, :City] => :city_without_place_polygon,
        [:QualityReport, :AddressTest, :CitiesWithoutPlaceNode, :City] => :city_without_place_node,
        [:QualityReport, :AddressTest, :AddressErrorList, :House] => nil,
        [:QualityReport, :AddressTest, :StreetErrors, :Street] => nil,
        [:QualityReport, :AddressTest, :StreetsOutsideCities, :Street] => :street_not_in_place,
        [:QualityReport, :RoutingTest, :SubgraphList, :Subgraph] => :routing_subgraph,
        [:QualityReport, :RoutingTestByLevel, :Trunk, :SubgraphList, :Subgraph] => :routing_subgraph_trunk,
        [:QualityReport, :RoutingTestByLevel, :Primary, :SubgraphList, :Subgraph] => :routing_subgraph_primary,
        [:QualityReport, :RoutingTestByLevel, :Secondary, :SubgraphList, :Subgraph] => :routing_subgraph_secondary,
        [:QualityReport, :RoutingTestByLevel, :Tertiary, :SubgraphList, :Subgraph] => :routing_subgraph_tertiary,
        [:QualityReport, :RoadDuplicatesTest, :DuplicateList, :DuplicatePoint] => :duplicate_point,
        [:QualityReport, :CoastLineTest, :BreakList, :BreakPoint] => :coastline_break,
        [:QualityReport, :DeadEndsTest, :DeadEndList, :DeadEnd] => :dead_end
      }

      def initialize(db)
        @db = db
        @stack = []
        @ctx = nil
      end

      def start_element(name)
        @stack.push name
        @ctx = {} if ERROR_STACKS.include? @stack
      end

      def end_element(name)
        raise StandardError.new("Wrong stack state: #{@stack.inspect}, but #{name} ending") if @stack.last != name

        if ERROR_STACKS.include? @stack
          @ctx[:type] ||= ERROR_STACKS[@stack]
          save_error
          @ctx = nil
        end

        @stack.pop
      end

      def text(value)
        return if @stack.include? :Summary

        if @stack == [:QualityReport, :AddressTest, :AddressErrorList, :House, :ErrType]
          @ctx[:type] = [nil, :building_not_in_place, :address_without_street, :address_street_not_found, :address_street_not_in_place, :address_by_territory, :address_street_not_routed][value.to_i]
        elsif @stack == [:QualityReport, :AddressTest, :StreetErrors, :Street, :ErrType]
          @ctx[:type] = [nil, :street_not_in_place][value.to_i]
        elsif @stack.last == :HouseNumber
          @ctx[:house_number] = Iconv.conv('UTF8','CP1251', value)
        elsif @stack.last == :Street
          @ctx[:street] = Iconv.conv('UTF8','CP1251', value)
        elsif @stack.last == :City
          @ctx[:city] = Iconv.conv('UTF8','CP1251', value)
        elsif @stack.last == :NumberOfRoads
          @ctx[:num_roads] = value.to_i
        elsif [:lat, :lon, :Lat, :Lon, :Lat1, :Lon1, :Lat2, :Lon2].include? @stack.last
          @ctx[@stack.last.to_s.downcase.to_sym] = value.to_f
        else
          #puts "Unknown text value in #{@stack.inspect}: #{value}"
        end
      end

      private

      def save_error
        if @ctx[:lat] && @ctx[:lon]
          @ctx[:geometry] = "POINT(#{@ctx[:lon]} #{@ctx[:lat]})"
        elsif @ctx[:lat1] && @ctx[:lon1] && @ctx[:lat2] && @ctx[:lon2]
          @ctx[:geometry] = "POLYGON((#{@ctx[:lon1]} #{@ctx[:lat1]},#{@ctx[:lon2]} #{@ctx[:lat1]},#{@ctx[:lon2]} #{@ctx[:lat2]},#{@ctx[:lon1]} #{@ctx[:lat2]},#{@ctx[:lon1]} #{@ctx[:lat1]}))"
        else
          raise StandardError.new("Error without geometry: #{@ctx.inspect}")
        end

        @ctx[:types] = [ @ctx.delete(:type).to_s ]
        @ctx[:params] = {}

        [:num_roads, :house_number, :street, :city].each do |key|
          @ctx[:params][key] = @ctx.delete(key) if @ctx[key] && @ctx[key] != ''
        end

        [:lat, :lon, :lat1, :lon1, :lat2, :lon2].each do |key|
          @ctx.delete key
        end

        @ctx[:source] = 'zkir'
        @ctx[:source_id] = Digest::SHA2.hexdigest "#{@ctx[:types]}|#{@ctx[:geometry]}"

        @ctx[:params] = @ctx[:params].hstore
        @ctx[:types] = @ctx[:types].pg_array

        @ctx[:updated_at] = Time.now
        @ctx[:deleted_at] = nil

        if @db
          if @db[:map_errors].where(:source => @ctx[:source], :source_id => @ctx[:source_id]).empty?
            @ctx[:created_at] = Time.now
            @db[:map_errors].insert @ctx
          else
            @db[:map_errors].where(:source => @ctx[:source], :source_id => @ctx[:source_id]).update @ctx
          end
        else
          puts @ctx.inspect
        end
      end

    end

    class << self

      def import_from! io
        require 'iconv'
        require 'digest/sha2'

        if defined? DB
          puts "Saving to #{DB}"

          Ox.sax_parse ::Importers::Zkir::Handler.new(DB), io
        else
          puts "No DB defined, just dumping results"

          Ox.sax_parse ::Importers::Zkir::Handler.new(nil), io
        end
      end

    end
  end
end
