require_relative '../../spec_helper'

class MThingy
  class NThingy
  end
end

describe Dataset::Record::Heirarchy, 'finder name' do
  it 'should collapse single character followed by underscore to just the single character' do
    @heirarchy = Dataset::Record::Heirarchy.new(Place)
    expect(@heirarchy.finder_name(MThingy)).to eq('mthingy')
    expect(@heirarchy.finder_name(MThingy::NThingy)).to eq('mthingy_nthingy')
  end
end
