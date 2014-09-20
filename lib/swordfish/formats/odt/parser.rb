module Swordfish
  module ODT
    module Parser

      # NODE PARSERS
      # Each of the methods below (beginning with '_node') are specialized parsers for handling
      # a particular type of XML element.

      # Parse a paragraph
      def _node_parse_paragraph(node)
        paragraph = Swordfish::Node::Paragraph.new
        text = Swordfish::Node::Text.new
        text.content = node.content
        paragraph.append text
        paragraph
      end

    end
  end
end
