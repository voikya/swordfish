# Superclass for all Swordfish::Node objects

module Swordfish
  module Node
    class Base

      attr_accessor :content
      attr_reader :children
      attr_reader :style

      # Initialize with a blank stylesheet and no children
      def initialize
        @style = Swordfish::Stylesheet.new []
        @children = []
      end

      # Append a node or nodes to this node as a child
      def append(node)
        @children ||= []
        @children << node
        @children.flatten!
      end

      # Take a style or styles and add them to this node's stylesheet
      def stylize(styles)
        @style.merge styles
      end

      # Every subclass must implement to_html in order to be converted to HTML
      def to_html
        raise NotImplementedError
      end

      # Given a hash, create instance variables for each key in that hash.
      # This is used for communication between nodes in the hierarchy.
      def inform!(hash)
        hash.each do |k, v|
          instance_variable_set "@#{k}", v
        end
      end

    end

    class BadContentError < Exception
    end
  end
end
