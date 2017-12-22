require 'spec_helper'

module Statefully
  describe Diff do
    let(:diff) { described_class.create(current: current, previous: previous) }

    context 'when created' do
      let(:current)  { State.create }
      let(:previous) { State::None.instance }

      it { expect(diff).to be_created }
    end

    context 'when key added' do
      let(:previous) { State.create }
      let(:current)  { previous.succeed(key: 'val') }

      it { expect(diff).not_to be_empty }
      it { expect(diff).not_to be_created }
      it { expect(diff.added).to have_key(:key) }
      it { expect(diff).to be_added(:key) }
      it { expect(diff.added.fetch(:key)).to eq 'val' }
      it { expect(diff.changed).to be_empty }

      it { expect(diff.inspect).to start_with '#<Statefully::Diff::Changed' }
      it { expect(diff.inspect).to include 'added={key: "val"}>' }
    end

    context 'when key changed' do
      let(:previous) { State.create(key: 'old') }
      let(:current)  { previous.succeed(key: 'new') }

      it { expect(diff).not_to be_empty }
      it { expect(diff.added).to be_empty }
      it { expect(diff.changed).to have_key(:key) }
      it { expect(diff).to be_changed(:key) }

      it { expect(diff.inspect).to include 'changed=' }

      context 'with change' do
        let(:change) { diff.changed.fetch(:key) }

        it { expect(change.current).to eq 'new' }
        it { expect(change.previous).to eq 'old' }
      end
    end

    context 'when nothing changed' do
      let(:current)  { State.create(key: 'key') }
      let(:previous) { current }

      it { expect(diff).to be_empty }
      it { expect(diff.inspect).to eq '#<Statefully::Diff::Unchanged>' }
    end

    shared_examples 'diff_is_empty' do
      it { expect(diff).to be_empty }
      it { expect(diff.added).to be_empty }
      it { expect(diff.changed).to be_empty }
    end

    context 'when failed' do
      let(:error)    { RuntimeError.new('boo!') }
      let(:previous) { State.create }
      let(:current)  { previous.fail(error) }

      it_behaves_like 'diff_is_empty'

      it { expect(diff.error).to eq error }

      it { expect(diff.inspect).to start_with '#<Statefully::Diff::Failed' }
      it { expect(diff.inspect).to include 'error=#<RuntimeError: boo!>' }
    end

    context 'when finished' do
      let(:previous) { State.create }
      let(:current)  { previous.finish }

      it_behaves_like 'diff_is_empty'

      it { expect(diff.inspect).to eq '#<Statefully::Diff::Finished>' }
    end
  end
end
