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
    end # describe 'trivial readers'

    describe '#succeed' do
      let(:new_val) { 'new_val' }
      let(:succeeded) { subject.succeed(new_key: new_val) }

      it { expect(succeeded).to be_success }
      it { expect(succeeded.old_key).to eq val }
      it { expect(succeeded.new_key).to eq new_val }
      it { expect(succeeded.keys).to eq %i[old_key new_key] }
      it { expect(succeeded.previous).to eq subject }
      it { expect(succeeded.resolve).to eq succeeded }

      context 'with history' do
        let(:history) { succeeded.history }

        it { expect(history.size).to eq 2 }
        it { expect(history.first.added).to include :new_key }
        it { expect(history.last.added).to include :old_key }
      end # context 'with history'
    end # describe '#succeed'

    describe '#fail' do
      let(:error)  { RuntimeError.new('snakes on a plane') }
      let(:failed) { subject.fail(error) }

      it { expect(failed).not_to be_success }
      it { expect(failed).to be_failure }
      it { expect(failed.old_key).to eq val }
      it { expect(failed.previous).to eq subject }
      it { expect(failed.error).to eq error }

      it 'raises passed error on #resolve' do
        expect { failed.resolve }.to raise_error do |err|
          expect(err).to eq error
        end
      end

      context 'with history' do
        let(:history) { failed.history }

        it { expect(history.size).to eq 2 }
        it { expect(history.first).to eq error }
        it { expect(history.last.added).to include :old_key }
      end # context 'with history'
    end # describe '#fail'
  end # describe 'State::Success'
end # module Statefully
