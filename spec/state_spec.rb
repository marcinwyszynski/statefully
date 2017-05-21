require 'spec_helper'

module Statefully
  describe State do
    describe '.create' do
      subject { described_class.create(key: 'val') }
      it      { expect(subject).to be_success }
    end # describe '.create'
  end # describe State

  describe 'State::Success' do
    let(:val) { 'val' }

    subject { State.create(old_key: val) }

    describe 'methods delegated to the underlying Hash' do
      it { expect(subject.keys).to eq [:old_key] }
      it { expect(subject.key?(:old_key)).to be_truthy }
      it { expect(subject.any? { |_, value| value == val }).to be_truthy }
    end # describe 'methods delegated to the underlying Hash'

    describe "methods dynamically dispatched using 'method_missing'" do
      it { expect(subject.old_key).to eq val }
      it { expect(subject.old_key?).to be_truthy }
      it { expect(subject.old_key!).to eq val }

      it { expect { subject.new_key }.to raise_error NoMethodError }
      it { expect(subject.new_key?).to be_falsey }
      it { expect { subject.new_key! }.to raise_error State::Missing }
    end # describe "methods dynamically dispatched using 'method_missing'"

    describe 'trivial readers' do
      it { expect(subject.resolve).to eq subject }
      it { expect(subject).to be_success }
      it { expect(subject).not_to be_failure }
      it { expect(subject).not_to be_finished }
    end # describe 'trivial readers'

    shared_examples 'successful_state' do
      it { expect(next_state).to be_success }
      it { expect(next_state.old_key).to eq val }

      it { expect(next_state.previous).to eq subject }
      it { expect(next_state.resolve).to eq next_state }
    end # shared_examples 'successful_state'

    describe '#succeed' do
      let(:new_val)    { 'new_val' }
      let(:next_state) { subject.succeed(new_key: new_val) }

      it_behaves_like 'successful_state'

      it { expect(next_state).not_to be_finished }
      it { expect(next_state.new_key).to eq new_val }
      it { expect(next_state.keys).to eq %i[old_key new_key] }

      context 'with history' do
        let(:history) { next_state.history }

        it { expect(history.size).to eq 2 }
        it { expect(history.first.added).to include :new_key }
        it { expect(history.last.added).to include :old_key }
      end # context 'with history'
    end # describe '#succeed'

    describe '#fail' do
      let(:error)      { RuntimeError.new('snakes on a plane') }
      let(:next_state) { subject.fail(error) }

      it { expect(next_state).not_to be_success }
      it { expect(next_state).to be_failure }
      it { expect(next_state).not_to be_finished }
      it { expect(subject).not_to be_finished }
      it { expect(next_state.old_key).to eq val }
      it { expect(next_state.previous).to eq subject }
      it { expect(next_state.error).to eq error }

      it 'raises passed error on #resolve' do
        expect { next_state.resolve }.to raise_error do |err|
          expect(err).to eq error
        end
      end

      context 'with history' do
        let(:history) { next_state.history }

        it { expect(history.size).to eq 2 }
        it { expect(history.first).to eq error }
        it { expect(history.last.added).to include :old_key }
      end # context 'with history'
    end # describe '#fail'

    describe '#finish' do
      let(:new_val)    { 'new_val' }
      let(:next_state) { subject.finish }

      it_behaves_like 'successful_state'

      it { expect(next_state).to be_finished }

      context 'with history' do
        let(:history) { next_state.history }

        it { expect(history.size).to eq 2 }
        it { expect(history.first).to eq :finished }
        it { expect(history.last.added).to include :old_key }
      end # context 'with history'
    end # describe '#finish'
  end # describe 'State::Success'
end # module Statefully
