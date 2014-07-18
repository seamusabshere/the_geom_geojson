require 'spec_helper'

dbname = 'the_geom_geojson_activerecord_test'
unless ENV['FAST'] == 'true'
  system 'dropdb', '--if-exists', dbname
  system 'createdb', dbname
  system 'psql', dbname, '--command', 'CREATE EXTENSION postgis'
  system 'psql', dbname, '--command', 'CREATE TABLE pets (id serial primary key, the_geom geometry(Geometry,4326), the_geom_webmercator geometry(Geometry,3857))'
end

require 'active_record'

ActiveRecord::Base.establish_connection "postgresql://127.0.0.1/#{dbname}"

ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.tap do |klass|
  klass::OID.register_type('geometry', klass::OID::Identity.new)
end

require 'the_geom_geojson/active_record'

class Pet < ActiveRecord::Base
  include TheGeomGeoJSON::ActiveRecord
end

if ENV['PRY'] == 'true'
  require 'pry'
  require 'logger'
  ActiveRecord::Base.logger = Logger.new($stdout).tap { |logger| logger.level = Logger::DEBUG }
  binding.pry
end

describe TheGeomGeoJSON do
  describe 'ActiveRecord' do
    # # select st_setsrid(st_geomfromgeojson('{"type":"Point","coordinates":[-73.1936,44.4775]}'),4326);
    #                      st_setsrid
    # ----------------------------------------------------
    #  0101000020E61000005C2041F1634C52C085EB51B81E3D4640
    # (1 row)
    let(:the_geom_expected) { '0101000020E61000005C2041F1634C52C085EB51B81E3D4640' }

    # # select st_transform(st_setsrid(st_geomfromgeojson('{"type":"Point","coordinates":[-73.1936,44.4775]}'),4326), 3857);
    #                     st_transform
    # ----------------------------------------------------
    #  0101000020110F000011410192E8145FC137D58F0ECD215541
    # (1 row)
    let(:the_geom_webmercator_expected) { '0101000020110F000011410192E8145FC137D58F0ECD215541' }

    before do
      Pet.delete_all
    end

    shared_examples 'the_geom_geojson=(geojson)' do
      it "sets the_geom" do
        expect(@pet.the_geom).to eq(the_geom_expected)
      end
      it "sets the_geom_webmercator" do
        expect(@pet.the_geom_webmercator).to eq(the_geom_webmercator_expected)
      end
      it "lets you access the_geom_geojson" do
        expect(@pet.the_geom_geojson).to eq(TheGeomGeoJSON::EXAMPLES[:burlington_point])
      end
    end

    describe "creating" do
      before do
        @pet = Pet.create! the_geom_geojson: TheGeomGeoJSON::EXAMPLES[:burlington_point]
      end
      it_behaves_like 'the_geom_geojson=(geojson)'
    end

    describe "building and saving" do
      before do
        @pet = Pet.new the_geom_geojson: TheGeomGeoJSON::EXAMPLES[:burlington_point]
        @pet.save!
      end
      it_behaves_like 'the_geom_geojson=(geojson)'
    end

    describe "modifying" do
      before do
        @pet = Pet.create!
        @pet.the_geom_geojson = TheGeomGeoJSON::EXAMPLES[:burlington_point]
        @pet.save!
      end
      it_behaves_like 'the_geom_geojson=(geojson)'
    end

    describe "building (without saving)" do
      before do
        @pet = Pet.new the_geom_geojson: TheGeomGeoJSON::EXAMPLES[:burlington_point]
      end
      it "raises exception if you try to access the_geom" do
        expect{@pet.the_geom}.to raise_error(TheGeomGeoJSON::Dirty)
      end
      it "raises exception if you try to access the_geom_webmercator" do
        expect{@pet.the_geom_webmercator}.to raise_error(TheGeomGeoJSON::Dirty)
      end
      it "lets you access the_geom_geojson" do
        expect(@pet.the_geom_geojson).to eq(TheGeomGeoJSON::EXAMPLES[:burlington_point])
      end
    end

  end
end