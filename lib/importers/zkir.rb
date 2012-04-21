require 'ox'

module Importers
  module Zkir

    class Handler < ::Ox::Sax

      def initialize(db)
        @db = db
        @stack = []
        @ctx = nil
      end

      def start_element(name)
        @stack.push name

        if @stack == [:QualityReport, :AddressTest, :CitiesWithoutPopulation, :City]
          @ctx = {:type => 'city_without_population'}
        elsif @stack == [:QualityReport, :AddressTest, :CitiesWithoutPlacePolygon, :City]
          @ctx = {:type => 'city_without_place_polygon'}
        elsif @stack == [:QualityReport, :AddressTest, :CitiesWithoutPlaceNode, :City]
          @ctx = {:type => 'city_without_place_node'}
        elsif @stack == [:QualityReport, :AddressTest, :AddressErrorList, :House]
          @ctx = {}
        elsif @stack == [:QualityReport, :AddressTest, :StreetErrors, :Street]
          @ctx = {}
        end
      end

      def end_element(name)
        raise StandardError.new("Wrong stack state: #{@stack.inspect}, but #{name} ending") if @stack.last != name

        if @stack == [:QualityReport, :AddressTest, :CitiesWithoutPopulation, :City]
          @ctx[:text] =  "Город без населения: #{@ctx[:city]}"
          save_error
          @ctx = nil
        elsif @stack == [:QualityReport, :AddressTest, :CitiesWithoutPlacePolygon, :City]
          @ctx[:text] =  "Город без полигональных границ: #{@ctx[:city]}"
          save_error
          @ctx = nil
        elsif @stack == [:QualityReport, :AddressTest, :CitiesWithoutPlaceNode, :City]
          @ctx[:text] =  "Город без точечного центра: #{@ctx[:city]}"
          save_error
          @ctx = nil
        end

        @stack.pop
      end

      def text(value)
        if @stack.last == :City
          @ctx[:city] = Iconv.conv('UTF8','CP1251', value)
        elsif @stack.last == :lat
          @ctx[:lat] = value.to_f
        elsif @stack.last == :lon
          @ctx[:lon] = value.to_f
        else
          #puts "Unknown text value in #{@stack.inspect}: #{value}"
        end
      end

      private

      def save_error
        @ctx[:geometry] = "POINT(#{@ctx[:lon]} #{@ctx[:lat]})"
        @ctx[:source] = 'zkir'
        @ctx[:source_id] = Digest::SHA2.hexdigest "#{@ctx[:type]}|#{@ctx[:geometry]}"
        @ctx.delete :city
        @ctx.delete :lat
        @ctx.delete :lon

        if @db
          @db[:osm_errors].insert @ctx
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
