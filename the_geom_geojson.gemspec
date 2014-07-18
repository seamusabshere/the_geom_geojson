# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'the_geom_geojson/version'

Gem::Specification.new do |spec|
  spec.name          = "the_geom_geojson"
  spec.version       = TheGeomGeoJSON::VERSION
  spec.authors       = ["Seamus Abshere"]
  spec.email         = ["seamus@abshere.net"]
  spec.summary       = %q{For PostGIS/PostgreSQL and ActiveRecord, provides "the_geom_geojson" getter and setter that update "the_geom" and "the_geom_webmercator" columns.}
  spec.description   = %q{Web mapping libraries like Leaflet often don't support PostGIS's native Well-Known Binary (WKB) and Well-Known Text (WKT) representation, but they do support GeoJSON, so this library helps translate between the two.}
  spec.homepage      = "https://github.com/seamusabshere/the_geom_geojson"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'activerecord'
  spec.add_runtime_dependency 'pg'
  
  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "yard"
  spec.add_development_dependency "pry"
end
