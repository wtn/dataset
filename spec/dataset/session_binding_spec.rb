require_relative '../spec_helper'

describe Dataset::SessionBinding do
  before :all do
    @database = Dataset::Database::Sqlite3.new({database: SQLITE_DATABASE}, File.join(SPEC_ROOT, 'tmp'))
  end

  before do
    @database.clear
    @binding = Dataset::SessionBinding.new(@database)
  end

  it 'should support direct record inserts like classic fixtures' do
    expect(Thing).not_to receive(:new)
    expect {
      return_value = @binding.create_record Thing
      expect(return_value).to be_kind_of(Integer)
    }.to change(Thing, :count).by(1)
  end

  it 'should support creating records by instantiating the record class so callbacks work' do
    thing = Thing.new
    expect(Thing).to receive(:new).and_return(thing)
    expect {
      return_value = @binding.create_model Thing
      expect(return_value).to be_kind_of(Thing)
    }.to change(Thing, :count).by(1)
  end

  it 'should provide itself to the instance loaders' do
    anything = Object.new
    anything.extend @binding.model_finders
    expect(anything.dataset_session_binding).to eq(@binding)
  end

  describe 'create_record' do
    it 'should accept raw attributes for the insert' do
      @binding.create_record Thing, name: 'my thing'
      expect(Thing.last.name).to eq('my thing')
    end

    it 'should optionally accept a symbolic name for later lookup' do
      id = @binding.create_record Thing, :my_thing, name: 'my thing'
      expect(@binding.find_model(Thing, :my_thing).id).to eq(id)
      expect(@binding.find_id(Thing, :my_thing)).to eq(id)
    end

    it 'should auto-assign _at and _on columns with their respective time types' do
      @binding.create_record Note
      expect(Note.last.created_at).not_to be_nil
      expect(Note.last.updated_at).not_to be_nil

      @binding.create_record Thing
      expect(Thing.last.created_on).not_to be_nil
      expect(Thing.last.updated_on).not_to be_nil
    end

    it 'should support belongs_to associations using symbolic name of associated type' do
      person_id = @binding.create_record Person, :person
      @binding.create_record Note, :note, person: :person
      expect(Note.last.person_id).to eq(person_id)
    end
  end

  describe 'create_model' do
    it 'should accept raw attributes for the insert' do
      @binding.create_model Thing, name: 'my thing'
      expect(Thing.last.name).to eq('my thing')
    end

    it 'should optionally accept a symbolic name for later lookup' do
      thing = @binding.create_model Thing, :my_thing, name: 'my thing'
      expect(@binding.find_model(Thing, :my_thing)).to eq(thing)
      expect(@binding.find_id(Thing, :my_thing)).to eq(thing.id)
    end

    it 'should support belongs_to associations using symbolic name of associated type' do
      person_id = @binding.create_record Person, :person
      @binding.create_model Note, :note, person: :person
      expect(Note.last.person_id).to eq(person_id)
    end
  end

  describe 'model finders' do
    before do
      @context = Object.new
      @context.extend @binding.model_finders
      @note_one = @binding.create_model Note, :note_one
    end

    it 'should not exist for types that have not been created' do
      expect {
        @context.things(:whatever)
      }.to raise_error(NoMethodError)
    end

    it 'should exist for the base classes of created types' do
      @binding.create_record State, :state_one
      expect(@context.places(:state_one)).not_to be_nil
      expect(@context.places(:state_one)).to eq(@context.states(:state_one))
    end

    it 'should exist for all ancestors' do
      @binding.create_record NorthCarolina, :nc
      expect(@context.states(:nc)).to eq(@context.north_carolinas(:nc))
    end

    it 'should exist for types made with create_model' do
      expect(@context.notes(:note_one)).to eq(@note_one)
      expect(@context.note_id(:note_one)).to eq(@note_one.id)
    end

    it 'should exist for types made with create_record' do
      id = @binding.create_record Note, :note_two
      expect(@context.notes(:note_two).id).to eq(id)
      expect(@context.note_id(:note_two)).to eq(id)
    end

    it 'should exist for types registered with name_model' do
      thing = Thing.create!
      @binding.name_model(thing, :thingy)
      expect(@context.things(:thingy)).to eq(thing)
    end

    it 'should support multiple names, returning an array' do
      note_two = @binding.create_model Note, :note_two
      expect(@context.notes(:note_one, :note_two)).to eq([@note_one, note_two])
      expect(@context.note_id(:note_one, :note_two)).to eq([@note_one.id, note_two.id])
    end

    it 'should support models inside modules' do
      @binding.create_record Nested::Place, :myplace, name: 'Home'
      expect(@context.nested_places(:myplace).name).to eq('Home')
    end
  end

  describe 'name_model' do
    before do
      @place = Place.create!
      @binding.name_model(@place, :myplace)
      @state = State.create!(name: 'NC')
      @binding.name_model(@state, :mystate)
    end

    it 'should allow assigning a name to a model for later lookup' do
      expect(@binding.find_model(Place, :myplace)).to eq(@place)
      expect(@binding.find_model(State, :mystate)).to eq(@state)
    end

    it 'should allow finding STI' do
      @context = Object.new
      @context.extend @binding.model_finders
      expect(@context.places(:myplace)).to eq(@place)
      expect(@context.places(:mystate)).to eq(@state)
      expect(@context.states(:mystate)).to eq(@state)
    end
  end

  describe 'name_to_sym' do
    it 'should convert strings to symbols' do
      expect(@binding.name_to_sym(nil)).to be_nil
      expect(@binding.name_to_sym('thing')).to eq(:thing)
      expect(@binding.name_to_sym('Mything')).to eq(:mything)
      expect(@binding.name_to_sym('MyThing')).to eq(:my_thing)
      expect(@binding.name_to_sym('My Thing')).to eq(:my_thing)
      expect(@binding.name_to_sym('"My Thing"')).to eq(:my_thing)
      expect(@binding.name_to_sym("'My Thing'")).to eq(:my_thing)
    end
  end

  describe 'nested bindings' do
    before do
      @binding.create_model Thing, :mything, name: 'my thing'
      @nested_binding = Dataset::SessionBinding.new(@binding)
    end

    it 'should walk up the tree to find models' do
      expect(@nested_binding.find_model(Thing, :mything)).to eq(@binding.find_model(Thing, :mything))
    end

    it 'should raise an error if an object cannot be found for a name' do
      expect {
        @nested_binding.find_model(Thing, :yourthing)
      }.to raise_error(Dataset::RecordNotFound, "There is no 'Thing' found for the symbolic name ':yourthing'.")

      expect {
        @nested_binding.find_id(Thing, :yourthing)
      }.to raise_error(Dataset::RecordNotFound, "There is no 'Thing' found for the symbolic name ':yourthing'.")
    end

    it 'should have instance loader methods from parent binding' do
      anything = Object.new
      anything.extend @nested_binding.model_finders
      expect(anything.things(:mything)).not_to be_nil
    end
  end
end
