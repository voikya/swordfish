# Superclass for all Swordfish::Node objects

module Swordfish
  module Node
    class Base

      attr_accessor :content
      attr_accessor :children
      attr_accessor :style

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

      # Replace a child node at a given index
      def replace(node, idx)
        @children[idx] = node
      end

      # Take a style or styles and add them to this node's stylesheet
      def stylize(styles)
        if styles.is_a? Hash
          # Key/value pairs
          styles.each do |k, v|
            @style.send "#{k}=".to_sym, v
          end
        else
          # Boolean values
          @style.merge styles
        end
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

      # Delete all child nodes
      def clear_children
        @children = []
      end

      # Wrap all children of type child_class with a new node of type wrapper_class
      def wrap_children(child_class, wrapper_class)
        new_node = wrapper_class.new
        new_node.append @children.select{|n| n.is_a? child_class}
        unless new_node.children.empty?
          idx = @children.find_index(new_node.children[0])
          @children = @children - new_node.children
          @children.insert idx, new_node
        end
      end

      # Find all descendant nodes of a given type
      def find_nodes_by_type(klass)
        nodes = @children.collect{|n| n.find_nodes_by_type(klass)}.flatten
        nodes << self if self.is_a?(klass)
        nodes.compact
      end

      # Return a clone of this node with a different class
      def replace_with(klass)
        if klass <= Swordfish::Node::Base
          new_node = klass.new
          new_node.inform!({:style => @style, :children => @children, :content => @content })
          new_node
        end
      end
    end

    class BadContentError < Exception
    end
  end
end
