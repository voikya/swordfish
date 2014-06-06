require 'zip'
require 'nokogiri'
require 'swordfish/document'
require_relative 'parser'

# Swordfish::DOCX defines a parser for .docx (Office OpenXML) formats

module Swordfish
  module DOCX
    class Document

      include Swordfish::DOCX::Parser

      attr_reader :swordfish_doc   # The Swordfish::Document corresponding to the parsed document
      attr_reader :docx_archive    # The source archive
      
      # Parse a document and return a Swordfish::Document object
      def self.open(filepath)
        # .docx is a zipped file format consisting of several XML files.
        # Read in the content of each needed file.
        docx_archive = Zip::File.open(filepath)

        xml_docs = {
          :document      => docx_archive.read('word/document.xml'),
          :styles        => docx_archive.read('word/styles.xml'),
          :numbering     => (docx_archive.read('word/numbering.xml') rescue nil),
          :relationships => (docx_archive.read('word/_rels/document.xml.rels') rescue nil),
          :footnotes     => (docx_archive.read('word/footnotes.xml') rescue nil),
          :footnote_rels => (docx_archive.read('word/_rels/footnotes.xml.rels') rescue nil),
          :endnotes      => (docx_archive.read('word/endnotes.xml') rescue nil),
          :endnote_rels  => (docx_archive.read('word/_rels/endnotes.xml.rels') rescue nil)
        }

        # Parse the XML files and generate the Swordfish::Document
        swordfish_docx = new docx_archive, xml_docs
        swordfish_docx.swordfish_doc
      end

      def initialize(archive, xml_docs)
        @docx_archive = archive
        @swordfish_doc = Swordfish::Document.new
        parse_styles xml_docs[:styles]
        parse_numbering(xml_docs[:numbering]) if xml_docs[:numbering]
        parse_relationships(xml_docs[:relationships]) if xml_docs[:relationships]
        parse_relationships(xml_docs[:footnote_rels], :footnotes) if xml_docs[:footnote_rels]
        parse_relationships(xml_docs[:endnote_rels], :endnotes) if xml_docs[:endnote_rels]
        parse_footnotes(xml_docs[:footnotes]) if xml_docs[:footnotes]
        parse_endnotes(xml_docs[:endnotes]) if xml_docs[:endnotes]
        parse xml_docs[:document]
      end

      private

      # Take the contents of the build buffer and flush them into the Swordfish::Document object.
      # This buffer is needed for certain docx constructs that consist of multiple top-level
      # elements but correspond to a single Swordfish::Node, such as lists.
      def flush
        @swordfish_doc.append(@buffer) if @buffer
        @buffer = nil
      end

      # Parse the document structure XML
      def parse(document_xml)
        @xml = Nokogiri::XML(document_xml)

        # Iterate over each element node and dispatch it to the appropriate parser
        @xml.xpath('//w:body').children.each do |node|
          case node.name
            when 'p'
              if node.xpath('.//w:numPr').length == 0 && (@buffer.is_a?(Swordfish::Node::List) ? node.xpath('.//w:ind').length.zero? : true)
                # Regular paragraph
                # (The buffer check makes sure that this isn't an indented paragraph immediately after a list item,
                # which means we're most likely dealing with a multi-paragraph list item)
                flush
                @swordfish_doc.append _node_parse_paragraph(node)
              elsif node.xpath('.//w:numPr/ancestor::w:pPrChange').length.zero?
                # List paragraph
                # (must have a numPr node, but cannot have a pPrChange ancestor, since that means
                # we are just looking at historical changes)
                # (Don't flush because we need to first ensure the list is fully parsed)
                _node_parse_list(node)
              end
            when 'tbl'
              flush
              @swordfish_doc.append _node_parse_table(node)
          end
        end
        flush
      end

      # Parse styles out of a docx element property nodeset (*Pr) and stylize the Swordfish::Node
      # If the Swordfish::Node is not provided, return a stylesheet instead
      def get_styles_for_node(xml_nodeset, swordfish_node = nil)
        return unless xml_nodeset
        swordfish_node = Swordfish::Node::Base.new if swordfish_node.nil?
        xml_nodeset.children.each do |style_node|
          case style_node.name
            when 'i'
              swordfish_node.stylize :italic
            when 'b'
              swordfish_node.stylize :bold
            when 'u'
              swordfish_node.stylize :underline
            when 'strike'
              swordfish_node.stylize :strikethrough
            when 'sz'
              swordfish_node.stylize :font_size => (style_node['w:val'].to_i / 2)
            when 'szCs' && !swordfish_node.style.font_size
              # Only use complex script size node if there is no standard size node
              swordfish_node.stylize :font_size => (style_node['w:val'].to_i / 2)
            when 'vertAlign'
              if style_node['w:val'] == 'superscript'
                swordfish_node.stylize :superscript
              elsif style_node['w:val'] == 'subscript'
                swordfish_node.stylize :subscript
              end
            when 'rStyle'
              if style_node['w:val'] == 'Strong'
                swordfish_node.stylize :strong
              elsif style_node['w:val'] == 'Emphasis'
                swordfish_node.stylize :emphasis
              end
          end
        end
        swordfish_node.style
      end

      # Parse the document styles XML
      def parse_styles(styles_xml)
        # This XML document defines a number of styles, which can be referenced by the document
        # XML in order to quickly reference repeated styles without having to redefine them for
        # every run. This function will load needed styles into a hash keyed by the style ID.
        @styles = {}
        xml = Nokogiri::XML(styles_xml)
        xml.xpath("//w:style").each do |style|
          style_id = style['w:styleId']
          stylesheet = get_styles_for_node(style.xpath(".//w:rPr"))
          @styles[style_id.to_sym] = stylesheet
        end
      end

      # Parse the abstract numbering XML (defining things such as list numbering)
      def parse_numbering(numbering_xml)
        # The XML maps a numbering ID (numId) to an abstract numbering schema ID (abstractNumId).
        # The abstract numbering schema defines display formats for each level of indentation (lvl).
        # This function will load up the relevant data into the @numbering class variable in the form
        # of a nested hash: @numbering[numbering ID][indentation level] = number format.
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

      # Parse the relationships XML (defining things such as internal references and external links)
      def parse_relationships(relationships_xml, type = nil)
        # The XML contains a list of relationships identified by an id. Each relationship includes
        # a target attribute designating the reference. THis function will load up the relevant
        # data into the @relationships class variable in the form of a hash:
        # @relationships[relationship ID] = target URI.
        rels = @relationships ||= {}
        rels = (@relationships[type] ||= {}) if type
        xml = Nokogiri::XML(relationships_xml)
        xml.css("Relationship").each do |rel| # Nokogiri doesn't seem to like XPath here for some reason
          rels[rel['Id']] = rel['Target']
        end
      end

      # Parse the footnotes XML
      def parse_footnotes(footnotes_xml)
        @footnotes = {}
        xml = Nokogiri::XML(footnotes_xml)
        xml.xpath("//w:footnote[@w:id > 0]").each do |footnote|
          id = footnote['w:id'].to_i
          f = Swordfish::Node::Footnote.new
          footnote.xpath(".//w:p").each do |p|
            f.append _node_parse_paragraph(p, :footnotes)
          end
          @footnotes[id] = f
        end
      end

      # Parse the endnotes XML
      def parse_endnotes(endnotes_xml)
        @endnotes = {}
        xml = Nokogiri::XML(endnotes_xml)
        xml.xpath("//w:endnote[@w:id > 0]").each do |endnote|
          id = endnote['w:id'].to_i
          f = Swordfish::Node::Footnote.new
          endnote.xpath(".//w:p").each do |p|
            f.append _node_parse_runs(p, :endnotes)
          end
          @endnotes[id] = f
        end
      end

      # Extract an image resource as a tempfile
      def read_image(image_name)
        tempfile = Tempfile.new(image_name)
        tempfile.write @docx_archive.get_input_stream("word/media/#{image_name}").read
        tempfile.close
        tempfile
      end

    end
  end
end
