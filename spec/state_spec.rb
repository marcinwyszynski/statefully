require 'spec_helper'

require 'pry'

module Statefully
  describe State do
    describe '.create' do
      let(:state) { described_class.create(**args) }

      context 'without keyword arguments' do
        let(:args) { {} }

        it { expect(state).to be_successful }

        context 'with diff' do
          let(:diff)     { state.diff }
          let(:expected) { '#<Statefully::Diff::Created' }

          it { expect(diff).to be_created }
          it { expect(diff.inspect).to start_with expected }
        end
      end

      context 'with keyword arguments' do
        let(:args) { { key: 'val' } }

        context 'with diff' do
          let(:diff)     { state.diff }
          let(:expected) { '#<Statefully::Diff::Created added={key: "val"}>' }

          it { expect(diff).to be_created }
          it { expect(diff.added).to include args }
        end
      end
    end
  end

  describe 'State::Success' do
    let(:val)   { 'val' }
    let(:state) { State.create(old_key: val) }

    describe 'methods delegated to the underlying Hash' do
      it { expect(state.keys).to eq %i[correlation_id old_key] }
      it { expect(state).to be_key(:old_key) }
      it { expect(state).to(be_any { |_, value| value == val }) }
    end

    describe "methods dynamically dispatched using 'method_missing'" do
      it { expect(state.old_key).to eq val }
      it { expect(state).to be_old_key }
      it { expect(state.old_key!).to eq val }

      it { expect { state.new_key }.to raise_error NoMethodError }
      it { expect(state).not_to be_new_key }
      it { expect { state.new_key! }.to raise_error Errors::StateMissing }
    end

    describe 'trivial readers' do
      it { expect(state.resolve).to eq state }
      it { expect(state).to be_successful }
      it { expect(state).not_to be_failed }
      it { expect(state).not_to be_finished }
    end

    describe '#ancestry' do
      let(:ancestry) { state.succeed.ancestry }

      it { expect(ancestry.count).to eq 2 }
      it { expect(ancestry.first).to eq state }
      it { expect(ancestry.last).to be_none }
    end

    describe '#history' do
      let(:history) { state.history }

      it { expect(history.length).to eq 1 }
      it { expect(history.first).to be_created }
    end

    describe '#inspect' do
      it { expect(state.inspect).to include 'old_key="val"' }
    end

    shared_examples 'successful_state' do
      it { expect(next_state).to be_successful }
      it { expect(next_state.old_key).to eq val }

      it { expect(next_state.previous).to eq state }
      it { expect(next_state.resolve).to eq next_state }
    end

    describe '#succeed' do
      let(:new_val)    { 'new_val' }
      let(:next_state) { state.succeed(new_key: new_val) }

      it_behaves_like 'successful_state'

      it { expect(next_state).not_to be_finished }
      it { expect(next_state.new_key).to eq new_val }
      it { expect(next_state.keys).to eq %i[correlation_id old_key new_key] }

      context 'with history' do
        let(:history) { next_state.history }

        it { expect(history.size).to eq 2 }
        it { expect(history.first).not_to be_created }
        it { expect(history.first.added).to include :new_key }
        it { expect(history.last.added).to include :old_key }
      end
    end

    describe '#fail' do
      let(:error)      { RuntimeError.new('boo!') }
      let(:next_state) { state.fail(error) }

      it { expect(next_state).not_to be_successful }
      it { expect(next_state).to be_failed }
      it { expect(next_state).not_to be_finished }
      it { expect(state).not_to be_finished }
      it { expect(next_state.old_key).to eq val }
      it { expect(next_state.previous).to eq state }
      it { expect(next_state.error).to eq error }
      it { expect { next_state.resolve }.to raise_error(error) }

      describe '#inspect' do
        let(:inspect) { next_state.inspect }

        it { expect(inspect).to start_with '#<Statefully::State::Failure' }
        it { expect(inspect).to include 'old_key="val"' }
        it { expect(inspect).to include 'error="#<RuntimeError: boo!>"' }
      end

      context 'with history' do
        let(:history) { next_state.history }

        it { expect(history.size).to eq 2 }
        it { expect(history.first.error).to eq error }
        it { expect(history.last.added).to include :old_key }
      end
    end

    describe '#finish' do
      let(:new_val)    { 'new_val' }
      let(:next_state) { state.finish }

      it_behaves_like 'successful_state'

      it { expect(next_state).to be_finished }

      context 'with history' do
        let(:history) { next_state.history }

        it { expect(history.size).to eq 2 }
        it { expect(history.first).to eq Diff::Finished.instance }
        it { expect(history.last.added).to include :old_key }
      end
    end
  end
end
