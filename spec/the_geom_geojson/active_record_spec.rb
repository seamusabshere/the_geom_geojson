require 'spec_helper'

dbname = 'the_geom_geojson_activerecord_test'
unless ENV['FAST'] == 'true'
  system 'dropdb', '--if-exists', dbname
  system 'createdb', dbname
  system 'psql', dbname, '--command', 'CREATE EXTENSION postgis'
  system 'psql', dbname, '--command', 'CREATE EXTENSION "uuid-ossp"'
  system 'psql', dbname, '--command', 'CREATE TABLE pets (id serial primary key, the_geom geometry(Geometry,4326), the_geom_webmercator geometry(Geometry,3857))'
  system 'psql', dbname, '--command', 'CREATE TABLE pet_alt_ids (alt_id serial primary key, the_geom geometry(Geometry,4326), the_geom_webmercator geometry(Geometry,3857))'
  system 'psql', dbname, '--command', 'CREATE TABLE pet_text_ids (id text unique not null, the_geom geometry(Geometry,4326), the_geom_webmercator geometry(Geometry,3857))'
  system 'psql', dbname, '--command', 'CREATE TABLE pet_uuids (id uuid unique not null, the_geom geometry(Geometry,4326), the_geom_webmercator geometry(Geometry,3857))'
  system 'psql', dbname, '--command', 'CREATE TABLE pet_auto_uuids (id uuid unique not null default uuid_generate_v4(), the_geom geometry(Geometry,4326), the_geom_webmercator geometry(Geometry,3857))'
end

require 'active_record'
require 'securerandom'

ActiveRecord::Base.establish_connection "postgresql://127.0.0.1/#{dbname}"

ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.tap do |klass|
  klass::OID.register_type('geometry', klass::OID::Identity.new)
end

require 'the_geom_geojson/active_record'

class Pet < ActiveRecord::Base
  include TheGeomGeoJSON::ActiveRecord
end

class PetAltId < ActiveRecord::Base
  include TheGeomGeoJSON::ActiveRecord
  self.primary_key = 'alt_id'
end

class PetTextId < ActiveRecord::Base
  include TheGeomGeoJSON::ActiveRecord
  self.primary_key = 'id'
end

class PetUuid < ActiveRecord::Base
  include TheGeomGeoJSON::ActiveRecord
  self.primary_key = 'id'
end

class PetAutoUuid < ActiveRecord::Base
  include TheGeomGeoJSON::ActiveRecord
  self.primary_key = 'id'

  before_save do
    self.id ||= SecureRandom.uuid
  end
end

if ENV['PRY'] == 'true'
  require 'pry'
  require 'logger'
  ActiveRecord::Base.logger = Logger.new($stdout).tap { |logger| logger.level = Logger::DEBUG }
  binding.pry
end

describe TheGeomGeoJSON do
  describe 'ActiveRecord' do
    # # SELECT ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[-73.193,44.477]}'), 4326);
    #                      st_setsrid
    # ----------------------------------------------------
    #  0101000020E61000003108AC1C5A4C52C0931804560E3D4640
    # (1 row)
    let(:the_geom_expected) { '0101000020E61000003108AC1C5A4C52C0931804560E3D4640' }

    # # SELECT ST_Transform(ST_SetSRID(ST_GeomFromGeoJSON('{"type":"Point","coordinates":[-73.193,44.477]}'), 4326), 3857);
    #                     st_transform
    # ----------------------------------------------------
    #  0101000020110F0000C22156DFD7145FC10858288EB9215541
    # (1 row)
    let(:the_geom_webmercator_expected) { '0101000020110F0000C22156DFD7145FC10858288EB9215541' }

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
      it "can be loaded from db" do
        if @pet.persisted?
          reloaded = pet_model.find @pet.id
          expect(reloaded.the_geom).to eq(the_geom_expected)
          expect(reloaded.the_geom_webmercator).to eq(the_geom_webmercator_expected)
          expect(reloaded.the_geom_geojson).to eq(TheGeomGeoJSON::EXAMPLES[:burlington_point])
        end
      end
      it "can be loaded with .with_geojson scope" do
        if @pet.persisted?
          reloaded = pet_model.with_geojson.find @pet.id
          expect(reloaded.the_geom_geojson).to eq(TheGeomGeoJSON::EXAMPLES[:burlington_point])
        end
      end
    end

    shared_examples 'different states of persistence' do
      describe "creating" do
        before do
          @pet = create_pet the_geom_geojson: TheGeomGeoJSON::EXAMPLES[:burlington_point]
        end
        it_behaves_like 'the_geom_geojson=(geojson)'
      end

      describe "building and saving" do
        before do
          @pet = build_pet the_geom_geojson: TheGeomGeoJSON::EXAMPLES[:burlington_point]
          @pet.save!
        end
        it_behaves_like 'the_geom_geojson=(geojson)'
      end

      describe "modifying" do
        before do
          @pet = create_pet
          @pet.the_geom_geojson = TheGeomGeoJSON::EXAMPLES[:burlington_point]
          @pet.save!
        end
        it_behaves_like 'the_geom_geojson=(geojson)'
      end

      describe "building (without saving)" do
        before do
          @pet = build_pet the_geom_geojson: TheGeomGeoJSON::EXAMPLES[:burlington_point]
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

    def create_pet(attrs = {})
      pet_model.create! attrs
    end
    def build_pet(attrs = {})
      pet_model.new attrs
    end

    describe "with autoincrement id" do
      def pet_model
        Pet
      end
      it_behaves_like 'different states of persistence'
    end

    describe "with alt id" do
      def pet_model
        PetAltId
      end
      it_behaves_like 'different states of persistence'
    end

    describe "with auto-generating uuid" do
      def pet_model
        PetAutoUuid
      end
      it_behaves_like 'different states of persistence'
    end

    describe "with text id" do
      def pet_model
        PetTextId
      end
      def create_pet(attrs = {})
        PetTextId.create! attrs.reverse_merge(id: rand.to_s)
      end
      def build_pet(attrs = {})
        PetTextId.new attrs.reverse_merge(id: rand.to_s)
      end
      it_behaves_like 'different states of persistence'
    end

    describe "with uuid id" do
      def pet_model
        PetUuid
      end
      def create_pet(attrs = {})
        PetUuid.create! attrs.reverse_merge(id: SecureRandom.uuid)
      end
      def build_pet(attrs = {})
        PetUuid.new attrs.reverse_merge(id: SecureRandom.uuid)
      end
      it_behaves_like 'different states of persistence'
    end
  end

  describe '::EXAMPLES' do
    TheGeomGeoJSON::EXAMPLES.each do |name, geojson|
      it "[:#{name}] respects the right-hand-rule" do
        pet = Pet.create the_geom_geojson: geojson
        rhr_geom = Pet.connection.execute("SELECT ST_ForceRHR(the_geom) FROM pets WHERE id = '#{pet.id}'").getvalue(0,0)
        expect(pet.the_geom).to eq(rhr_geom)
      end
    end
  end
end
