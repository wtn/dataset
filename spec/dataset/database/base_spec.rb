require_relative '../../spec_helper'

describe Dataset::Database::Base do
  before do
    @database = Dataset::Database::Base.new
  end

  it 'should clear the tables of all AR classes' do
    Place.create!
    Thing.create!
    @database.clear
    expect(Place.count).to eq(0)
    expect(Thing.count).to eq(0)
  end

  it 'should not clear the "schema_migrations" table' do
    ActiveRecord::Base.connection.execute("INSERT INTO schema_migrations (version) VALUES ('testing123')")
    @database.clear
    result = ActiveRecord::Base.connection.select_one("SELECT version FROM schema_migrations WHERE version = 'testing123'")
    expect(result).not_to be_nil
  end
end
