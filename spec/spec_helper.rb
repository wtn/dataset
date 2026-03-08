SPEC_ROOT = __dir__
RAILS_ROOT = File.expand_path('..', SPEC_ROOT)

$LOAD_PATH << SPEC_ROOT
$LOAD_PATH << File.join(RAILS_ROOT, 'lib')

RAILS_LOG_FILE = File.join(RAILS_ROOT, 'log/test.log')
SQLITE_DATABASE = File.join(SPEC_ROOT, 'sqlite3.db')

require 'fileutils'
FileUtils.mkdir_p(File.dirname(RAILS_LOG_FILE))
FileUtils.touch(RAILS_LOG_FILE)
FileUtils.mkdir_p(File.join(SPEC_ROOT, 'tmp'))
FileUtils.rm_rf(Dir.glob(File.join(SPEC_ROOT, 'tmp/*')))
FileUtils.rm_f(SQLITE_DATABASE)

require 'active_record'
require 'logger'

ActiveRecord::Base.logger = Logger.new(RAILS_LOG_FILE)
ActiveRecord::Base.logger.level = Logger::DEBUG

ActiveRecord::Base.configurations = {'test' => {
  'adapter' => 'sqlite3',
  'database' => SQLITE_DATABASE,
}}
ActiveRecord::Base.establish_connection :test
load File.join(SPEC_ROOT, 'schema.rb')

require 'models'
require 'dataset'
