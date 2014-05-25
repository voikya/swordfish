require 'zip'
require 'nokogiri'
require 'paper/document'

module Paper
  class DOCX

    attr_reader :paper_doc
    
    def self.open(filepath)
      docx_archive = Zip::File.open(filepath)
      document = docx_archive.read 'word/document.xml'
      styles = docx_archive.read 'word/styles.xml'
      numbering = docx_archive.read 'word/numbering.xml'
      relationships = docx_archive.read 'word/_rels/document.xml.rels'

      paper_docx = new document, styles, numbering, relationships
      paper_docx.paper_doc
    end

    def initialize(document_xml, styles_xml, numbering_xml, relationships_xml)
      @paper_doc = Paper::Document.new
      parse_styles styles_xml
      parse_numbering numbering_xml
      parse_relationships relationships_xml
      parse document_xml
    end

  private

    def flush
      @paper_doc.append(@buffer) if @buffer
      @buffer = nil
    end

    def parse(document_xml)
      @xml = Nokogiri::XML(document_xml)
      @xml.xpath('//w:body').children.each do |node|
        case node.name
          when 'p'
            if node.xpath('.//w:numPr').length == 0
              # Regular paragraph
              flush
              @paper_doc.append _node_parse_paragraph(node)
            else
              # List paragraph
              _node_parse_list(node)
            end
        end
      end
      flush
    end

    def get_styles_for_node(paper_node, xml_nodeset)
      return unless xml_nodeset
      xml_nodeset.children.each do |style_node|
        case style_node.name
          when 'i'
            paper_node.stylize :italic
          when 'b'
            paper_node.stylize :bold
          when 'u'
            paper_node.stylize :underline
        end
      end
    end

    def parse_styles(styles_xml)
    end

    def parse_numbering(numbering_xml)
      @numbering = {}
      xml = Nokogiri::XML(numbering_xml)
      xml.xpath("//w:num").each do |num|
        numId = num['w:numId'].to_i
        abstractNumId = num.xpath("./w:abstractNumId")[0]['w:val'].to_i
        abstract_numbering = {}
        xml.xpath("//w:abstractNum[@w:abstractNumId='#{abstractNumId}']/w:lvl").each do |level_format|
          level = level_format['w:ilvl'].to_i
          format = level_format.xpath("./w:numFmt")[0]['w:val']
          abstract_numbering[level] = format
        end
        @numbering[numId] = abstract_numbering
      end
    end

    def parse_relationships(relationships_xml)
      @relationships = {}
      xml = Nokogiri::XML(relationships_xml)
      xml.css("Relationship").each do |rel| # Nokogiri doesn't seem to like XPath here for some reason
        @relationships[rel['Id']] = rel['Target']
      end
    end

    def _node_parse_runs(node)
      texts = []
      node.children.each do |run_xml|
        case run_xml.name
          when 'r' 
            text = Paper::Node::Text.new
            text.content = run_xml.xpath('./w:t')[0].content
            get_styles_for_node(text, run_xml.xpath('./w:rPr')[0])
            texts << text
          when 'hyperlink'
            link = Paper::Node::Hyperlink.new
            link.href = @relationships[run_xml['r:id']]
            _node_parse_runs(run_xml).each {|r| link.append(r)}
            texts << link
        end
      end
      texts
    end

    def _node_parse_paragraph(node)
      paragraph = Paper::Node::Paragraph.new
      _node_parse_runs(node).each {|r| paragraph.append(r)}
      paragraph
    end

    def _node_parse_list(node)
      list_item = Paper::Node::ListItem.new
      _node_parse_runs(node).each {|r| list_item.append(r)}
      level = node.xpath(".//w:numPr/w:ilvl")[0]['w:val'].to_i
      numbering_scheme = node.xpath(".//w:numPr/w:numId")[0]['w:val'].to_i

      unless @buffer
        @buffer = Paper::Node::List.new
        @buffer.stylize @numbering[numbering_scheme][level].to_sym
      end

      if @buffer.depth_of_final_node >= level
        # Add sibling to existing list
        target = @buffer
        level.times do
          target = target.last_list_item.nested_list
        end
        target.append list_item
      elsif @buffer.depth_of_final_node < level
        # Add new nested list
        target = @buffer
        (level - 1).times do
          target = target.last_list_item.nested_list
        end
        list = Paper::Node::List.new
        list.append list_item
        list.stylize @numbering[numbering_scheme][level].to_sym
        target.last_list_item.append list
      end
    end
  end
end
