require_relative 'the_geom_geojson/version'

require 'rgeo'
require 'rgeo/geo_json'

module TheGeomGeoJSON
  Dirty = Class.new(RuntimeError)

  class << self
    def ewkb_to_geojson(ewkb)
      parser = RGeo::WKRep::WKBParser.new nil, support_ewkb: true
      JSON.dump RGeo::GeoJSON.encode(parser.parse(ewkb))
    end
  end
end
