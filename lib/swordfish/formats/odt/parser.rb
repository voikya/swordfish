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

      # Parse a list
      def _node_parse_list(node, nesting_opts = {})
        nesting_opts[:depth] ||= 1
        nesting_opts[:style] ||= node['text:style-name'].to_sym
        list = Swordfish::Node::List.new
        list.style = @styles[nesting_opts[:style]][nesting_opts[:depth]]
        node.xpath('./text:list-item').each do |list_item_xml|
          list_item = Swordfish::Node::ListItem.new
          list_item_xml.children.each do |c|
            case c.name
              when 'p'
                para = _node_parse_paragraph(c)
                # If this is the only child of type paragraph, skip the paragraph
                # and just append its children directly to the list item
                if list_item_xml.xpath('./text:p').length == 1
                  list_item.append para.children
                else
                  list_item.append para
                end
              when 'list'
                nesting_opts[:depth] += 1
                list_item.append _node_parse_list(c, nesting_opts)
            end
          end
          list.append list_item
        end
        list
      end

    end
  end
end
