require 'spec_helper'

module Statefully
  module Errors
    describe StateMissing do
      let(:field) { :bacon }
      let(:error) { described_class.new(field) }

      it { expect(error.field).to eq field }
      it { expect(error.message).to eq "field 'bacon' missing from state" }
    end
  end
end
