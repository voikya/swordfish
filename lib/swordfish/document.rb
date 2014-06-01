require 'cgi'
require 'swordfish/stylesheet'
require 'swordfish/nodes/base'
require 'swordfish/nodes/text'
require 'swordfish/nodes/paragraph'
require 'swordfish/nodes/list'
require 'swordfish/nodes/list_item'
require 'swordfish/nodes/hyperlink'
require 'swordfish/nodes/table'
require 'swordfish/nodes/table_row'
require 'swordfish/nodes/table_cell'
require 'swordfish/nodes/image'

# Swordfish::Document is the internal representation of a parsed document.

module Swordfish
  class Document
    
    attr_reader :nodes    # An array of all top-level elements in the document
    attr_accessor :images # Stored image assets

    # On initialization, set the nodes list to an empty array
    def initialize
      @nodes = []
      @images = {}
    end

    # Pass in a node and append it to the nodes array
    def append(node)
      if Swordfish::Node.constants.include? node.class.to_s.split('::').last.to_sym
        @nodes << node
      else
        raise ArgumentError, "Object is not a node"
      end
    end

    # Retrieve an image by name
    def get_image(name)
      @images[name]
    end

    # Save an image to a specified directory
    def save_image(image, dest)
      @images[image].open
      File.open(dest, 'w') { |f| f.write(@images[image].read) }
      @images[image].close
    end

    # Change the value that an image should report its source to be
    def update_image_path(original_name, new_path)
      find_nodes_by_type(Swordfish::Node::Image).each do |image_node|
        if image_node.original_name == original_name
          image_node.path = new_path
        end
      end
    end

    def to_html
      @nodes.map(&:to_html).join
    end

    private

    # Return all nodes of a given type
    def find_nodes_by_type(klass)
      @nodes.collect{|n| n.find_nodes_by_type(klass)}.flatten
    end
  end
end
