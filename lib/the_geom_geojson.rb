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

    #{"type":"GeometryCollection","geometries":[{"type":"Polygon","coordinates":[[[-73.223,
    #{"type":"FeatureCollection","features":[{"type":"Feature","properties":{},"geometry":{"type":"Polygon","coordinates":[[[-73.223,
    def sanitize_geojson(v)
      if v.is_a?(String) and (v.include?('GeometryCollection') or v.include?('FeatureCollection'))
        v = JSON.parse v
      end
      case v
      when String
        v
      when Hash
        geometries = case v.fetch('type')
        when 'GeometryCollection'
          v.fetch('geometries')
        when 'FeatureCollection'
          v.fetch('features').map { |feature| feature['geometries'] || feature['geometry'] }
        when 'Polygon', 'MultiPolygon'
          [v]
        end
        raise "can only handle 1 geometries" if geometries.length > 1
        geometries[0].to_json
      else
        raise "#the_geom_geojson= expects String or Hash"
      end
    end
  end
end
