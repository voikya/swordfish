# A list item node

module Paper
  module Node
    class ListItem < Base

      def to_html
        "<li>#{@children.map(&:to_html).join}</li>"
      end

      # Return the nested list, or nil if this list item has no nested lists
      def nested_list
        @children.last.is_a?(Paper::Node::List) ? @children.last : nil
      end

    end
  end
end
