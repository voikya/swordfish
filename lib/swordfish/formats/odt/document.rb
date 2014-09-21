require 'zip'
require 'nokogiri'
require 'swordfish/document'
require_relative 'parser'

# Swordfish::ODT defines a parser for .odt (Open Document) formats

module Swordfish
  module ODT
    class Document

      include Swordfish::ODT::Parser
      
      attr_reader :swordfish_doc   # The Swordfish::Document corresponding to the parsed document
      attr_reader :odt_archive     # The source archive

      # Parse a document and return a Swordfish::Document object
      def self.open(filepath)
        # .odt is a zipped file format consisting of several XML files.
        # Read in the content of each needed file.
        odt_archive = Zip::File.open(filepath)

        xml_docs = {
          :content => odt_archive.read('content.xml'),
          :styles  => odt_archive.read('styles.xml')
        }

        # Parse the XML files and generate the Swordfish::Document
        swordfish_odt = new odt_archive, xml_docs
        swordfish_odt.swordfish_doc
      end

      def initialize(archive, xml_docs)
        @odt_archive = archive
        @swordfish_doc = Swordfish::Document.new
        parse_styles xml_docs[:styles]
        parse_styles xml_docs[:content]
        parse xml_docs[:content]
      end

      private

      # Parse the document structure XML
      def parse(document_xml)
        @xml = Nokogiri::XML(document_xml)

        # Iterate over each element and dispatch it to the appropriate parser
        @xml.xpath('//office:text').children.each do |node|
          case node.name
            when 'p'
              @swordfish_doc.append _node_parse_paragraph(node)
          end
        end
      end

      # Parse document styles XML
      def parse_styles(xml_doc)
        # Right now this only looks for named styles and does not take into account default
        # style definitions. Styles may be defined in multiple different places within a
        # given ODT doc.
        @styles = {}
        xml = Nokogiri::XML(xml_doc)
        xml.xpath('//style:style[@style:name]').each do |style|
          name = style['style:name']
          swordfish_node = Swordfish::Node::Base.new
          style.xpath('./style:text-properties').each do |text_properties|
            text_properties.attributes.each do |k, v|
              case k
                when 'font-style'
                  swordfish_node.stylize(:italic) if v.value.match /italic/
                when 'font-weight'
                  swordfish_node.stylize(:bold) if v.value.match /bold/
                when 'text-underline-style'
                  swordfish_node.stylize(:underline) unless v.value.match /none/
                when 'text-line-through-type'
                  swordfish_node.stylize(:strikethrough) unless v.value.match /none/
                when 'text-position'
                  if v.value.match /super/
                    swordfish_node.stylize(:superscript)
                  elsif v.value.match /sub/
                    swordfish_node.stylize(:subscript)
                  end
              end
            end
          end
          puts swordfish_node.style.inspect
          @styles[name.to_sym] = swordfish_node.style
        end
      end
    end
  end
end
