module Dataset
  module Database # :nodoc:

    # The interface to a sqlite3 database, this will capture by copying the db
    # file and restore by replacing and reconnecting to one of the same.
    #
    class Sqlite3 < Base
      def initialize(database_spec, storage_path)
        @database_path, @storage_path = database_spec[:database], storage_path
        FileUtils.mkdir_p(@storage_path)
      end

      def capture(datasets)
        return if datasets.nil? || datasets.empty?
        ActiveRecord::Base.connection.execute('PRAGMA wal_checkpoint(TRUNCATE)')
        cp @database_path, storage_path(datasets)
      end

      def restore(datasets)
        store = storage_path(datasets)
        if File.file?(store)
          ActiveRecord::Base.connection_handler.clear_all_connections!
          FileUtils.rm_f(wal_path)
          FileUtils.rm_f(shm_path)
          mv store, @database_path
          ActiveRecord::Base.establish_connection :test
          true
        end
      end

      def storage_path(datasets)
        "#{@storage_path}/#{datasets.collect {|c| c.__id__}.join('_')}.sqlite3.db"
      end

      private

      def wal_path
        "#{@database_path}-wal"
      end

      def shm_path
        "#{@database_path}-shm"
      end
    end
  end
end
