require 'set'
require 'singleton'

module Statefully
  module Diff
    # This method reeks of :reek:FeatureEnvy (of current).
    def create(current, previous)
      return current.diff if current.failed? || current.finished?
      changes = Builder.new(current, previous).build
      changes.empty? ? Unchanged.instance : Changed.new(**changes).freeze
    end
    module_function :create

    class Changed
      attr_reader :added, :changed

      def empty?
        false
      end

      def inspect
        "#<#{self.class.name} #{inspect_details}>"
      end

      def added?(key)
        added.key?(key)
      end

      def changed?(key)
        changed.key?(key)
      end

      private

      def inspect_details
        [inspect_added, inspect_changed].compact.join(', ')
      end

      def inspect_added
        added.empty? ? nil : "added=#{Inspect.from_hash(added)}"
      end

      def inspect_changed
        changed.empty? ? nil : "changed=#{Inspect.from_hash(changed)}"
      end

      def initialize(added:, changed:)
        @added = added.freeze
        @changed = changed.freeze
      end
    end # class Changed

    module NoChanges
      def empty?
        true
      end

      def added
        {}
      end

      def changed
        {}
      end
    end # module NoChanges
    private_constant :NoChanges

    class Unchanged
      include Singleton
      include NoChanges

      def inspect
        "#<#{self.class.name}>"
      end
    end # class Unchanged

    class Failed
      include NoChanges
      attr_reader :error

      def initialize(error)
        @error = error
      end

      def inspect
        "#<#{self.class.name} error=#{error.inspect}>"
      end
    end # class Failed

    class Finished < Unchanged
    end # class Finished

    class Change
      attr_reader :current, :previous

      def initialize(current, previous)
        @current = current
        @previous = previous
      end

      def none?
        @current == @previous
      end

      def inspect
        "#<#{self.class.name} " \
        "#{Inspect.from_fields(current: current, previous: previous)}>"
      end
    end # class Change

    class Builder
      def initialize(current, previous)
        @current = current
        @previous = previous
      end

      def build
        empty? ? {} : { added: added, changed: changed }
      end

      private

      def added
        @added ||=
          (current_keys - previous_keys)
          .map { |key| [key, @current.fetch(key)] }
          .to_h
      end

      def changed
        @changed ||=
          (current_keys & previous_keys)
          .map { |key| [key, change_for(key)] }
          .to_h
          .reject { |_, val| val.none? }
      end

      def change_for(key)
        Change.new(@current.fetch(key), @previous.fetch(key)).freeze
      end

      def empty?
        added.empty? && changed.empty?
      end

      def current_keys
        Set.new(@current.keys)
      end

      def previous_keys
        Set.new(@previous.keys)
      end
    end # class Builder
    private_constant :Builder
  end # module Diff
end # module Statefully
