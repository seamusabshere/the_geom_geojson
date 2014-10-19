module TheGeomGeoJSON
  module ActiveRecord
    class << self
      def included(model)
        model.class_eval do
          scope :with_geojson, -> { select('*', 'ST_AsGeoJSON(the_geom) AS the_geom_geojson') }

          after_save do
            if @the_geom_geojson_dirty
              raise "can't update the_geom without an id" if id.nil?
              model.connection_pool.with_connection do |c|
                c.execute TheGeomGeoJSON::ActiveRecord.sql(model, id, @the_geom_geojson_change)
              end
              @the_geom_geojson_dirty = false
              reload
            end
          end
        end
      end

      # @private
      def sql(model, id, the_geom_geojson)
        sql = (@sql[model.name] ||= begin
          cols = model.column_names
          has_the_geom, has_the_geom_webmercator = cols.include?('the_geom'), cols.include?('the_geom_webmercator')
          raise "Can't set the_geom_geojson on #{model.name} because it lacks both the_geom and the_geom_webmercator columns" unless has_the_geom or has_the_geom_webmercator
          memo = []
          memo << "UPDATE #{model.quoted_table_name} SET "
          memo << 'the_geom = ST_SetSRID(ST_GeomFromGeoJSON(?), 4326)'                                  if has_the_geom
          memo << ',' if has_the_geom && has_the_geom_webmercator
          memo << 'the_geom_webmercator  = ST_Transform(ST_SetSRID(ST_GeomFromGeoJSON(?), 4326), 3857)' if has_the_geom_webmercator
          memo << " WHERE #{model.quoted_primary_key} = ?"
          memo.join.freeze
        end)
        model.send :sanitize_sql_array, [sql, the_geom_geojson, the_geom_geojson, id]
      end
    end

    # memoizes update sql with bind placeholders
    @sql = {}

    def the_geom_geojson=(v)
      @the_geom_geojson_dirty = true
      @the_geom_geojson_change = v
    end

    
    def the_geom_geojson
      if @the_geom_geojson_dirty
        @the_geom_geojson_change
      elsif preselected = read_attribute(:the_geom_geojson)
        preselected
      elsif the_geom
        started_at = Time.now
        memo = TheGeomGeoJSON.ewkb_to_geojson the_geom
        if (elapsed = Time.now - started_at) > 0.1
          $stderr.puts "[the_geom_geojson] EWKB->GeoJSON parsing took #{elapsed}s, recommend using #{self.class.name}.with_geojson scope"
        end
        memo
      end
    end

    def the_geom
      if @the_geom_geojson_dirty
        raise TheGeomGeoJSON::Dirty, "the_geom can't be accessed on #{self.class.name} id #{id.inspect} until it has been saved"
      else
        read_attribute :the_geom
      end
    end

    def the_geom_webmercator
      if @the_geom_geojson_dirty
        raise TheGeomGeoJSON::Dirty, "the_geom_webmercator can't be accessed on #{self.class.name} id #{id.inspect} until it has been saved"
      else
        read_attribute :the_geom_webmercator
      end
    end

  end
end
