# A list item node

module Swordfish
  module Node
    class ListItem < Base

      def to_html
        "<li>#{@children.map(&:to_html).join.strip}</li>"
      end

      # Return the nested list, or nil if this list item has no nested lists
      def nested_list
        @children.last.is_a?(Swordfish::Node::List) ? @children.last : nil
      end

    end
  end
end
