require_relative 'the_geom_geojson/version'

require 'rgeo'
require 'rgeo/geo_json'

module TheGeomGeoJSON
  Dirty = Class.new(RuntimeError)
end
