# TheGeomGeoJSON

[![Build Status](https://travis-ci.org/seamusabshere/the_geom_geojson.svg?branch=master)](https://travis-ci.org/seamusabshere/the_geom_geojson)

For PostGIS/PostgreSQL and ActiveRecord, provides `the_geom_geojson` getter and setter that update `the_geom geometry(Geometry,4326)` and `the_geom_webmercator geometry(Geometry,3857)` columns.

Web mapping libraries like [Leaflet](http://leafletjs.com/) often don't support PostGIS's native [Well-Known Binary (WKB) and Well-Known Text (WKT)](http://postgis.net/docs/using_postgis_dbmanagement.html#OpenGISWKBWKT) representation, but they do support [GeoJSON](http://geojson.org/), so this library helps translate between the two.

<img src="https://www.nyu.edu/greyart/exhibits/cisneros/images/garcianew.jpg" alt="Composición constructiva 16" />

## Requirements

* [PostgreSQL](postgresql.org) >=9
* [PostGIS](http://postgis.net/) 2.0.0 with [support for JSON-C >= 0.9 compiled in](http://www.postgis.org/docs/ST_GeomFromGeoJSON.html)
* [ActiveRecord](http://guides.rubyonrails.org/active_record_querying.html) >=4
* if it exists, column `the_geom` must be [WGS 84 SRID 4326](http://spatialreference.org/ref/epsg/wgs-84/)
* if it exists, column `the_geom_webmercator` must be [spherical mercator SRID 3857](http://spatialreference.org/ref/sr-org/epsg3857/) (which is basically identical and should be used in preference to [Google webmercator unofficial SRID 900913](http://trac.osgeo.org/openlayers/wiki/SphericalMercator)).

## Why `the_geom` and `the_geom_webmercator`?

Per the commonly used [CartoDB column naming convention](http://docs.cartodb.com/tutorials/projections.html), you have a table like:

```sql
CREATE TABLE pets (
  id                    serial primary key,
  the_geom              geometry(Geometry,4326),
  the_geom_webmercator  geometry(Geometry,3857)
)
```

## Usage with ActiveRecord

You simply include it in your models:

```ruby
class Pet < ActiveRecord::Base
  include TheGeomGeoJSON::ActiveRecord
end
```

Then:

```
[1] > jerry = Pet.create!
SQL (1.0ms)  INSERT INTO "pets" DEFAULT VALUES RETURNING "id"
=> #<Pet id: 1, the_geom: nil, the_geom_webmercator: nil>

[2] > jerry.the_geom_geojson = '{"type":"Point","coordinates":[-72.4861,44.1853]}'
=> "{\"type\":\"Point\",\"coordinates\":[-72.4861,44.1853]}"

[3] > jerry.save!
SQL (1.5ms)  UPDATE "pets" SET the_geom = ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[-72.4861,44.1853]}'), 4326), the_geom_webmercator = ST_Transform(ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[-72.4861,44.1853]}'), 4326), 3857) WHERE id = 1
Pet Load (0.3ms)  SELECT  "pets".* FROM "pets"  WHERE "pets"."id" = $1 LIMIT 1  [["id", 1]]
=> true

[4] > jerry.the_geom
=> "0101000020E61000007AA52C431C1F52C072F90FE9B7174640"

[5] > jerry.the_geom_webmercator
=> "0101000020110F0000303776EFFEC75EC11E1648AD64F55441"
```

If you see warnings like:

```
unknown OID 136825: failed to recognize type of 'the_geom'. It will be treated as String.
```

... then [define the OID](http://gray.fm/2013/09/17/unknown-oid-with-rails-and-postgresql/) by creating `config/initializers/active_record_postgis`:

```sql
ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.tap do |klass|
  klass::OID.register_type('geometry', klass::OID::Identity.new)
end
```

## Corporate support

<p><a href="http://faraday.io" alt="Faraday"><img src="https://s3.amazonaws.com/creative.faraday.io/logo.png" alt="Faraday logo"/></a></p>

## Known issues

1. It's hard to install PostGIS with JSON-C support on Mac OS X
2. The `the_geom_geojson` getter is rather inefficient - it's assumed you'll mostly use the setter

## Contributing

1. Fork it ( https://github.com/seamusabshere/the_geom_geojson/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Copyright

Copyright 2014 Faraday
