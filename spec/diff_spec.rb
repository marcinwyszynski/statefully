require 'spec_helper'

module Statefully
  describe Diff do
    subject { described_class.create(current, previous) }

    context 'when key added' do
      let(:current)  { State.create(key: 'val') }
      let(:previous) { State.create }

      it { expect(subject).not_to be_empty }
      it { expect(subject.added).to have_key(:key) }
      it { expect(subject.added?(:key)).to be_truthy }
      it { expect(subject.added.fetch(:key)).to eq 'val' }
      it { expect(subject.changed).to be_empty }
    end # context 'when key added'

    context 'when key changed' do
      let(:current)  { State.create(key: 'new') }
      let(:previous) { State.create(key: 'old') }

      it { expect(subject).not_to be_empty }
      it { expect(subject.added).to be_empty }
      it { expect(subject.changed).to have_key(:key) }
      it { expect(subject.changed?(:key)).to be_truthy }

      context 'with change' do
        let(:change) { subject.changed.fetch(:key) }

        it { expect(change.current).to eq 'new' }
        it { expect(change.previous).to eq 'old' }
      end # context 'with change'
    end # context 'when key changed'

    context 'when nothing changed' do
      let(:current)  { State.create(key: 'key') }
      let(:previous) { current }

      it { expect(subject).to be_empty }
    end # context 'when nothing changed'
  end # describe Diff
end # module Statefully
