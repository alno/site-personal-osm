require 'ox'

module Importers
  module Zkir

    class Handler < ::Ox::Sax

      ERROR_STACKS = [
        [:QualityReport, :AddressTest, :CitiesWithoutPopulation, :City],
        [:QualityReport, :AddressTest, :CitiesWithoutPlacePolygon, :City],
        [:QualityReport, :AddressTest, :CitiesWithoutPlaceNode, :City],
        [:QualityReport, :AddressTest, :AddressErrorList, :House],
        [:QualityReport, :AddressTest, :StreetErrors, :Street],
        [:QualityReport, :RoutingTest, :SubgraphList, :Subgraph],
        [:QualityReport, :RoutingTestByLevel, :Trunk, :SubgraphList, :Subgraph],
        [:QualityReport, :RoutingTestByLevel, :Primary, :SubgraphList, :Subgraph],
        [:QualityReport, :RoutingTestByLevel, :Secondary, :SubgraphList, :Subgraph],
        [:QualityReport, :RoutingTestByLevel, :Tertiary, :SubgraphList, :Subgraph],
        [:QualityReport, :RoadDuplicatesTest, :DuplicateList, :DuplicatePoint],
        [:QualityReport, :CoastLineTest, :BreakList, :BreakPoint],
      ]

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

        if @stack == [:QualityReport, :AddressTest, :CitiesWithoutPopulation, :City]
          @ctx[:type] = :city_without_population
          save_error
          @ctx = nil
        elsif @stack == [:QualityReport, :AddressTest, :CitiesWithoutPlacePolygon, :City]
          @ctx[:type] = :city_without_place_polygon
          save_error
          @ctx = nil
        elsif @stack == [:QualityReport, :AddressTest, :CitiesWithoutPlaceNode, :City]
          @ctx[:type] = :city_without_place_node
          save_error
          @ctx = nil
        elsif @stack == [:QualityReport, :RoutingTest, :SubgraphList, :Subgraph]
          @ctx[:type] = :routing_subgraph
          save_error
          @ctx = nil
        elsif @stack == [:QualityReport, :RoutingTestByLevel, :Trunk, :SubgraphList, :Subgraph]
          @ctx[:type] = :routing_subgraph_trunk
          save_error
        elsif @stack == [:QualityReport, :RoutingTestByLevel, :Primary, :SubgraphList, :Subgraph]
          @ctx[:type] = :routing_subgraph_primary
          save_error
          @ctx = nil
        elsif @stack == [:QualityReport, :RoutingTestByLevel, :Secondary, :SubgraphList, :Subgraph]
          @ctx[:type] = :routing_subgraph_secondary
          save_error
          @ctx = nil
        elsif @stack == [:QualityReport, :RoutingTestByLevel, :Tertiary, :SubgraphList, :Subgraph]
          @ctx[:type] = :routing_subgraph_tertiary
          save_error
          @ctx = nil
        elsif @stack == [:QualityReport, :RoadDuplicatesTest, :DuplicateList, :DuplicatePoint]
          @ctx[:type] = :duplicate_point
          save_error
          @ctx = nil
        elsif @stack == [:QualityReport, :AddressTest, :AddressErrorList, :House]
          save_error
          @ctx = nil
        elsif @stack == [:QualityReport, :AddressTest, :StreetErrors, :Street]
          save_error
          @ctx = nil
        elsif @stack == [:QualityReport, :CoastLineTest, :BreakList, :BreakPoint]
          @ctx[:type] = :coastline_break
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

        @ctx[:source] = 'zkir'
        @ctx[:source_id] = Digest::SHA2.hexdigest "#{@ctx[:type]}|#{@ctx[:geometry]}"
        @ctx[:type] = @ctx[:type].to_s
        @ctx[:params] = {}

        [:num_roads, :house_number, :street, :city].each do |key|
          @ctx[:params][key] = @ctx.delete(key) if @ctx[key] && @ctx[key] != ''
        end

        @ctx[:params] = @ctx[:params].hstore

        [:lat, :lon, :lat1, :lon1, :lat2, :lon2].each do |key|
          @ctx.delete key
        end

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

      def import_from_url! url
        require 'tempfile'

        file = Tempfile.new 'import'

        `wget '#{url}' -O #{file.path}`

        import_from! file
      end

    end
  end
end
