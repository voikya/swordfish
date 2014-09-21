module Swordfish
  module ODT
    module Parser

      # NODE PARSERS
      # Each of the methods below (beginning with '_node') are specialized parsers for handling
      # a particular type of XML element.

      # Parse a paragraph
      def _node_parse_paragraph(node)
        paragraph = Swordfish::Node::Paragraph.new
        text = _node_parse_text(node)
        paragraph.append text
        paragraph
      end

      # Parse text content
      def _node_parse_text(node)
        node.children.map do |c|
          text = Swordfish::Node::Text.new
          text.content = c.content
          if c['text:style-name']
            stylesheet = @styles[c['text:style-name'].to_sym]
            text.style = stylesheet if stylesheet
          end
          text
        end
      end

    end
  end
end
