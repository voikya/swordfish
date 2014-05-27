require 'paper/stylesheet'
require 'paper/nodes/base'
require 'paper/nodes/text'
require 'paper/nodes/paragraph'
require 'paper/nodes/list'
require 'paper/nodes/list_item'
require 'paper/nodes/hyperlink'
require 'paper/nodes/table'
require 'paper/nodes/table_row'
require 'paper/nodes/table_cell'

# Paper::Document is the internal representation of a parsed document.

module Paper
  class Document
    
    attr_reader :nodes   # An array of all top-level elements in the document

    # On initialization, set the nodes list to an empty array
    def initialize
      @nodes = []
    end

    # Pass in a node and append it to the nodes array
    def append(node)
      if Paper::Node.constants.include? node.class.to_s.split('::').last.to_sym
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
