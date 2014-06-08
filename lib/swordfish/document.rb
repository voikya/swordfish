require 'cgi'
require 'uri'
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
require 'swordfish/nodes/header'
require 'swordfish/nodes/footnote'
require 'swordfish/nodes/raw'

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

    # Perform various destructive operations that may result in improved output
    def settings(opts = {})
      find_headers! if opts[:guess_headers]
      find_footnotes! if opts[:footnotes]
      @generate_full_document = !!opts[:full_document]
      self
    end

    def to_html
      if @generate_full_document
        prefix = "<!DOCTYPE html><html><head><title></title></head><body>"
        suffix = "</body></html>"
        prefix + @nodes.map(&:to_html).join + suffix
      else
        @nodes.map(&:to_html).join
      end
    end

    private

    # Return all nodes of a given type
    def find_nodes_by_type(klass)
      @nodes.collect{|n| n.find_nodes_by_type(klass)}.flatten
    end

    # Attempt to identify header nodes
    def find_headers!
      font_sizes = []
      # If a paragraph has a single font size throughout, mark it in the array.
      @nodes.each_with_index do |node, idx|
        if node.is_a?(Swordfish::Node::Paragraph)
          para_size = node.style.font_size
          run_sizes = node.children.collect{ |n| n.style.font_size }.compact
          if (run_sizes.length == 1) || (run_sizes.length == 0 && para_size)
            font_sizes << {:idx => idx, :size => run_sizes.first || para_size}
          end
        end
      end

      # For each node with a consistent size, if it is larger than both of
      # its neighbors, flag it as a header
      header_sizes = []
      font_sizes.each_with_index do |f, idx|
        if idx == 0
          header_sizes << f[:size] if f[:size] > font_sizes[idx+1][:size]
        elsif idx != font_sizes.length - 1
          header_sizes << f[:size] if (f[:size] > font_sizes[idx-1][:size] && f[:size] > font_sizes[idx+1][:size])
        end
      end
      header_sizes = header_sizes.uniq.sort.reverse
      font_sizes.each do |f|
        level = header_sizes.find_index(f[:size])
        if level
          header = @nodes[f[:idx]].replace_with(Swordfish::Node::Header)
          header.inform! :level => (level + 1)
          @nodes[f[:idx]] = header
        end
      end
    end

    # Find all foot/endnotes and number them
    def find_footnotes!
      find_nodes_by_type(Swordfish::Node::Footnote).each_with_index do |footnote, idx|
        footnote.inform!({:index => idx})
        footnote_content = Swordfish::Node::Raw.new
        footnote_content.content = footnote.content_to_html
        @nodes << footnote_content
      end
    end

  end
end
