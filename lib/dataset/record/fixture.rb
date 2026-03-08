module Dataset
  module Record # :nodoc:

    class Fixture # :nodoc:
      attr_reader :meta, :symbolic_name, :session_binding

      def initialize(meta, attributes, symbolic_name, session_binding)
        @meta            = meta
        @attributes      = attributes.stringify_keys
        @symbolic_name   = symbolic_name || object_id
        @session_binding = session_binding

        install_default_attributes!
      end

      def create
        conn = record_class.connection
        hash = to_hash
        columns = hash.keys.map {|k| conn.quote_column_name(k) }.join(', ')
        values = hash.values.map {|v| conn.quote(v) }.join(', ')
        conn.execute "INSERT INTO #{conn.quote_table_name(meta.table_name)} (#{columns}) VALUES (#{values})"
        id
      end

      def id
        @attributes['id']
      end

      def record_class
        meta.record_class
      end

      def to_hash
        hash = @attributes.dup
        hash[meta.inheritance_column] = meta.sti_name if meta.inheriting_record?
        record_class.reflections.each do |name, reflection|
          name = name.to_s
          add_reflection_attributes(hash, name, reflection) if hash[name]
        end
        hash
      end

      def install_default_attributes!
        @attributes['id'] ||= symbolic_name.to_s.hash.abs
        install_timestamps!
      end

      def install_timestamps!
        meta.timestamp_columns.each do |column|
          @attributes[column.name] = now unless @attributes.key?(column.name)
        end
      end

      def now
        tz = ActiveRecord.default_timezone rescue ActiveRecord::Base.default_timezone
        time = tz == :utc ? Time.now.utc : Time.now
        time.to_fs(:db)
      end

      private
        def add_reflection_attributes(hash, name, reflection)
          value = hash.delete(name)
          case value
          when Symbol
            hash[reflection.foreign_key.to_s] = session_binding.find_id(reflection.klass, value)
          else
            hash[reflection.foreign_key.to_s] = value
          end
        end
    end

  end
end
