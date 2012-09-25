require 'oj'
require 'lib/importers/base'

module Importers
  class Json < Importers::Base

    class << self

      def import! source, io
        importer = self.new source, global_db

        json = Oj.load(io)
        json['data'].each do |err|
          importer.import_error! err
        end
      end

    end

    def import_error! err
      err[:geometry] = geojson_to_wkt err.delete('geometry')
      err[:types] = [ err.delete('type') ].flatten
      err[:params] = err.delete('params')
      err[:url] = err.delete('url')

      save_error! err
    end

  end
end
