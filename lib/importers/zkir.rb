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
          @ctx[:text] =  "Город без населения: #{@ctx[:city]}"
          save_error
          @ctx = nil
        elsif @stack == [:QualityReport, :AddressTest, :CitiesWithoutPlacePolygon, :City]
          @ctx[:type] = :city_without_place_polygon
          @ctx[:text] =  "Город без полигональных границ: #{@ctx[:city]}"
          save_error
          @ctx = nil
        elsif @stack == [:QualityReport, :AddressTest, :CitiesWithoutPlaceNode, :City]
          @ctx[:type] = :city_without_place_node
          @ctx[:text] =  "Город без точечного центра: #{@ctx[:city]}"
          save_error
          @ctx = nil
        elsif @stack == [:QualityReport, :AddressTest, :AddressErrorList, :House]
          desc = {
            :building_not_in_place => 'Здание вне населенного пункта',
            :address_without_street => 'Улица не задана',
            :address_street_not_found => 'Улица не найдена',
            :address_street_not_in_place => 'Улица не связана с городом',
            :address_by_territory => 'Здание номеруется по территории',
            :address_street_not_routed => 'Улица не является рутинговой в СГ'
          }

          @ctx[:text] =  "#{desc[@ctx[:type]]}: #{@ctx[:city] || '?'}, #{@ctx[:street] || '?'}, #{@ctx[:house_number]}"
          save_error
          @ctx = nil
        elsif @stack == [:QualityReport, :AddressTest, :StreetErrors, :Street]
          desc = {
            :street_not_in_place => 'Улица за пределами города'
          }

          @ctx[:text] =  "#{desc[@ctx[:type]]}: #{@ctx[:city] || '?'}, #{@ctx[:street] || '?'}"
          save_error
          @ctx = nil
        elsif @stack == [:QualityReport, :RoutingTest, :SubgraphList, :Subgraph]
          @ctx[:type] = :routing_subgraph
          @ctx[:text] =  "Изолированный рутинговый подграф (#{@ctx[:num_roads]} дорог): #{@ctx[:city] || '?'}, #{@ctx[:street] || '?'}"
          save_error
          @ctx = nil
        elsif @stack == [:QualityReport, :RoutingTestByLevel, :Trunk, :SubgraphList, :Subgraph]
          @ctx[:type] = :routing_subgraph_trunk
          @ctx[:text] =  "Изолированный рутинговый подграф на уровне Trunk (#{@ctx[:num_roads]} дорог): #{@ctx[:city] || '?'}, #{@ctx[:street] || '?'}"
          save_error
        elsif @stack == [:QualityReport, :RoutingTestByLevel, :Primary, :SubgraphList, :Subgraph]
          @ctx[:type] = :routing_subgraph_primary
          @ctx[:text] =  "Изолированный рутинговый подграф на уровне Primary (#{@ctx[:num_roads]} дорог): #{@ctx[:city] || '?'}, #{@ctx[:street] || '?'}"
          save_error
          @ctx = nil
        elsif @stack == [:QualityReport, :RoutingTestByLevel, :Secondary, :SubgraphList, :Subgraph]
          @ctx[:type] = :routing_subgraph_secondary
          @ctx[:text] =  "Изолированный рутинговый подграф на уровне Secondary (#{@ctx[:num_roads]} дорог): #{@ctx[:city] || '?'}, #{@ctx[:street] || '?'}"
          save_error
          @ctx = nil
        elsif @stack == [:QualityReport, :RoutingTestByLevel, :Tertiary, :SubgraphList, :Subgraph]
          @ctx[:type] = :routing_subgraph_tertiary
          @ctx[:text] =  "Изолированный рутинговый подграф на уровне Tertiary (#{@ctx[:num_roads]} дорог): #{@ctx[:city] || '?'}, #{@ctx[:street] || '?'}"
          save_error
          @ctx = nil
        elsif @stack == [:QualityReport, :RoadDuplicatesTest, :DuplicateList, :DuplicatePoint]
          @ctx[:type] = :duplicate_point
          @ctx[:text] =  "Точка-дубликат"
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

        [:num_roads, :house_number, :street, :city, :lat, :lon, :lat1, :lon1, :lat2, :lon2].each do |key|
          @ctx.delete key
        end

        if @db
          if @db[:osm_errors].where(:source => @ctx[:source], :source_id => @ctx[:source_id]).empty?
            @db[:osm_errors].insert @ctx
          else
            @db[:osm_errors].where(:source => @ctx[:source], :source_id => @ctx[:source_id]).update @ctx
          end
        else
          puts @ctx.inspect
        end
      end

    end

    class << self

      def import! io
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
