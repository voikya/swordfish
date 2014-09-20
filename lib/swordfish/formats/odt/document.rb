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
    end
  end
end
