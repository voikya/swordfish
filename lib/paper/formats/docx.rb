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

      paper_docx = new document, styles
      paper_docx.paper_doc
    end

    def initialize(document_xml, styles_xml)
      @paper_doc = Paper::Document.new
      parse document_xml, styles_xml
    end

  private

    def parse(document_xml, styles_xml)
      @xml = Nokogiri::XML(document_xml)
      @xml.xpath('//w:body').children.each do |node|
        case node.name
          when 'p'
            paragraph = Paper::Node::Paragraph.new
            node.xpath('./w:r').each do |run_xml|
              text = Paper::Node::Text.new
              text.content = run_xml.xpath('./w:t')[0].content
              get_styles_for_node(text, run_xml.xpath('./w:rPr')[0])
              paragraph.append(text)
            end
            @paper_doc.append paragraph
        end
      end
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

  end
end
