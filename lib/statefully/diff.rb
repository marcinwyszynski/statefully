require 'set'
require 'singleton'

module Statefully
  class Diff
    attr_reader :added, :changed

    def self.create(current, previous)
      changes = Builder.new(current, previous).build
      changes.empty? ? None.instance : new(**changes).freeze
    end

    def empty?
      false
    end

    def inspect
      "<#{self.class.name} #{inspect_details}>"
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

    class None
      include Singleton

      def empty?
        true
      end

      def added
        {}
      end

      def changed
        false
      end

      def inspect
        "<#{self.class.name}>"
      end
    end # class None

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
  end # class Diff
end # module Statefully
