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

# Swordfish::Document is the internal representation of a parsed document.

module Swordfish
  class Document
    
    attr_reader :nodes   # An array of all top-level elements in the document

    # On initialization, set the nodes list to an empty array
    def initialize
      @nodes = []
    end

    # Pass in a node and append it to the nodes array
    def append(node)
      if Swordfish::Node.constants.include? node.class.to_s.split('::').last.to_sym
        @nodes << node
      else
        raise ArgumentError, "Object is not a node"
      end
    end

    def to_html
      @nodes.map(&:to_html).join
    end
  end
end
