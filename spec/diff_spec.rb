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

      it { expect(subject.inspect).to start_with '#<Statefully::Diff::Changed' }
      it { expect(subject.inspect).to include 'added={key: "val"}>' }
    end # context 'when key added'

    context 'when key changed' do
      let(:current)  { State.create(key: 'new') }
      let(:previous) { State.create(key: 'old') }

      it { expect(subject).not_to be_empty }
      it { expect(subject.added).to be_empty }
      it { expect(subject.changed).to have_key(:key) }
      it { expect(subject.changed?(:key)).to be_truthy }

      it { expect(subject.inspect).to include 'changed=' }

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
      it { expect(subject.inspect).to eq '#<Statefully::Diff::Unchanged>' }
    end # context 'when nothing changed'

    shared_examples 'diff_is_empty' do
      it { expect(subject).to be_empty }
      it { expect(subject.added).to be_empty }
      it { expect(subject.changed).to be_empty }
    end # shared_examples 'diff_is_empty'

    context 'when failed' do
      let(:error)    { RuntimeError.new('boo!') }
      let(:previous) { State.create }
      let(:current)  { previous.fail(error) }

      it_behaves_like 'diff_is_empty'

      it { expect(subject.error).to eq error }

      it { expect(subject.inspect).to start_with '#<Statefully::Diff::Failed' }
      it { expect(subject.inspect).to include 'error=#<RuntimeError: boo!>' }
    end # context 'when failed'

    context 'when finished' do
      let(:previous) { State.create }
      let(:current)  { previous.finish }

      it_behaves_like 'diff_is_empty'

      it { expect(subject.inspect).to eq '#<Statefully::Diff::Finished>' }
    end # context 'when finished'
  end # describe Diff
end # module Statefully
