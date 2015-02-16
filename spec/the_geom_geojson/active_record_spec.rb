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
    let(:the_geom_expected) { '0103000020E6100000010000000600000083C0CAA1454E52C0022B8716D93E46406DE7FBA9F14A52C01F85EB51B83E4640D34D6210584952C0F0A7C64B373946402FDD2406814D52C0D578E926313846402DB29DEFA74E52C04260E5D0223B464083C0CAA1454E52C0022B8716D93E4640' }
    let(:the_geom_webmercator_expected) { '0103000020110F00000100000006000000213FC2C41A185FC1B8ACA6A9DB2355417F507E9D73125FC1B31193A6B4235541B0E24EDEBB0F5FC1CCA725C4271D5541FACC63CFCC165FC16AE385ECEF1B5541337871BFC1185FC1F8C0EA95701F5541213FC2C41A185FC1B8ACA6A9DB235541' }

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
        expect(@pet.the_geom_geojson).to eq(TheGeomGeoJSON::EXAMPLES[:burlington])
      end
      it "lets you access a simplified the_geom_geojson" do
        expect(@pet.the_geom_geojson(simplify: 0.03).length).to be < @pet.the_geom_geojson.length
      end
      it "can be loaded from db" do
        if @pet.persisted?
          reloaded = pet_model.find @pet.id
          expect(reloaded.the_geom).to eq(the_geom_expected)
          expect(reloaded.the_geom_webmercator).to eq(the_geom_webmercator_expected)
          expect(reloaded.the_geom_geojson).to eq(TheGeomGeoJSON::EXAMPLES[:burlington])
        end
      end
      it "can be loaded with .with_geojson scope" do
        if @pet.persisted?
          reloaded = pet_model.with_geojson.find @pet.id
          expect(reloaded.the_geom_geojson).to eq(TheGeomGeoJSON::EXAMPLES[:burlington])
        end
      end
    end

    shared_examples 'different states of persistence' do
      describe "creating" do
        before do
          @pet = create_pet the_geom_geojson: TheGeomGeoJSON::EXAMPLES[:burlington]
        end
        it_behaves_like 'the_geom_geojson=(geojson)'
      end

      describe "building and saving" do
        before do
          @pet = build_pet the_geom_geojson: TheGeomGeoJSON::EXAMPLES[:burlington]
          @pet.save!
        end
        it_behaves_like 'the_geom_geojson=(geojson)'
      end

      describe "modifying" do
        before do
          @pet = create_pet
          @pet.the_geom_geojson = TheGeomGeoJSON::EXAMPLES[:burlington]
          @pet.save!
        end
        it_behaves_like 'the_geom_geojson=(geojson)'
      end

      describe "building (without saving)" do
        before do
          @pet = build_pet the_geom_geojson: TheGeomGeoJSON::EXAMPLES[:burlington]
        end
        it "raises exception if you try to access the_geom" do
          expect{@pet.the_geom}.to raise_error(TheGeomGeoJSON::Dirty)
        end
        it "raises exception if you try to access the_geom_webmercator" do
          expect{@pet.the_geom_webmercator}.to raise_error(TheGeomGeoJSON::Dirty)
        end
        it "lets you access the_geom_geojson" do
          expect(@pet.the_geom_geojson).to eq(TheGeomGeoJSON::EXAMPLES[:burlington])
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
