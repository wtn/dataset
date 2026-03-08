require 'fileutils'

module Dataset
  module Database # :nodoc:

    PROTECTED_TABLES = %w[schema_migrations ar_internal_metadata].freeze

    # Provides Dataset a way to clear, dump and load databases.
    class Base
      include FileUtils

      def clear
        connection = ActiveRecord::Base.connection
        connection.tables.each do |table_name|
          next if PROTECTED_TABLES.include?(table_name)
          connection.delete "DELETE FROM #{connection.quote_table_name(table_name)}", 'Dataset::Database#clear'
        end
      end

      def record_heirarchy(record_class)
        base_class = record_class.base_class
        record_heirarchies[base_class] ||= Dataset::Record::Heirarchy.new(base_class)
      end

      def record_meta(record_class)
        record_metas[record_class] ||= begin
          heirarchy = record_heirarchy(record_class)
          heirarchy.update(record_class)
          Dataset::Record::Meta.new(heirarchy, record_class)
        end
      end

      protected
        def record_metas
          @record_metas ||= Hash.new
        end

        def record_heirarchies
          @record_heirarchies ||= Hash.new
        end
    end
  end
end
