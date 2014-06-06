require 'zip'
require 'nokogiri'
require 'swordfish/document'

# Swordfish::DOCX defines a parser for .docx (Office OpenXML) formats

module Swordfish
  class DOCX

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

    # NODE PARSERS
    # Each of the methods below (beginning with '_node') are specialized parsers for handling
    # a particular type of XML element.

    # Parse one or more runs
    def _node_parse_runs(node, context = nil)
      # The 'run' is the basic unit of text in Office OpenXML. A paragraph, table cell, or other
      # block element may contain one or more runs, and each run has an associated set of styles.
      texts = []
      # A complex field is a special type of node spanning multiple runs, where most of the runs
      # designate a special control flow rather than normal text.
      complex_field = nil

      nodes = node.is_a?(Array) ? node : node.children
      nodes.each_with_index do |run_xml, idx|
        case run_xml.name
          when 'r'
            if run_xml.xpath('./w:t').length > 0 && complex_field.nil?
              # A True run node
              # Only examine the run if it includes text codes. The run may also include
              # things like comment nodes, which should be ignored.
              text = Swordfish::Node::Text.new
              text.content = run_xml.xpath('./w:t')[0].content
              get_styles_for_node(run_xml.xpath('./w:rPr')[0], text)
              texts << text
            elsif run_xml.xpath('.//*[name()="pic:pic"]').length > 0
              # An image run
              image = Swordfish::Node::Image.new
              relationship_id = run_xml.xpath('.//*[name()="pic:pic"]/*[name()="pic:blipFill"]/*[name()="a:blip"]')[0]['r:embed'] rescue nil
              if relationship_id
                image.original_name = @relationships[relationship_id].split('/').last
                @swordfish_doc.images[image.original_name] = read_image(image.original_name)
                texts << image
              end
            elsif run_xml.xpath('./w:fldChar').length > 0 || complex_field
              # A complex field
              case
                when run_xml.xpath('./w:fldChar').length > 0 && run_xml.xpath('./w:fldChar')[0]['w:fldCharType'] == 'begin'
                  # Start the complex field
                  complex_field = true
                when run_xml.xpath('./w:instrText').length > 0
                  # An instruction run, defining the complex field's behavior
                  instruction = run_xml.xpath('./w:instrText')[0].content
                  if instruction =~ /^\s*HYPERLINK/
                    # A hyperlink
                    complex_field = Swordfish::Node::Hyperlink.new
                    complex_field.href = instruction.match(/^\s*HYPERLINK "([^"]+)"/).captures[0]
                  else
                    # Anything else
                    complex_field = Swordfish::Node::Text.new
                  end
                when run_xml.xpath('./w:t').length > 0 && complex_field.children.length.zero?
                  # The textual content
                  complex_field.append(_node_parse_runs(nodes.to_a[idx..-1]))
                when run_xml.xpath('./w:fldChar').length > 0 && run_xml.xpath('./w:fldChar')[0]['w:fldCharType'] == 'end'
                  # End the complex field
                  if complex_field
                    texts << complex_field
                    complex_field = nil
                  else
                    # Handle the case where _node_parse_runs gets called from within a complex field
                    return texts
                  end
              end
            elsif run_xml.xpath('./w:footnoteReference').length > 0
              # A footnote reference
              id = run_xml.xpath('./w:footnoteReference')[0]['w:id'].to_i
              texts << @footnotes[id]
            elsif run_xml.xpath('./w:endnoteReference').length > 0
              # An endnote reference
              id = run_xml.xpath('./w:endnoteReference')[0]['w:id'].to_i
              texts << @endnotes[id]
            end
          when 'hyperlink'
            # Hyperlink nodes are placed amongst other run nodes, but
            # they themselves also contain runs. Hyperlinks include
            # a relationship ID attribute defining their reference.
            link = Swordfish::Node::Hyperlink.new
            link.href = context ? @relationships[context][run_xml['r:id']] : @relationships[run_xml['r:id']]
            _node_parse_runs(run_xml).each {|r| link.append(r)}
            texts << link
        end
      end
      # Clean up runs by merging them if they have identical styles
      texts = texts.reduce([]) do |memo, run|
        if memo.length > 0 && memo.last.is_a?(Swordfish::Node::Text) && run.is_a?(Swordfish::Node::Text) && memo.last.style == run.style
          memo.last.content += run.content
        else
          memo << run
        end
        memo
      end

      texts
    end

    # Parse a paragraph
    def _node_parse_paragraph(node)
      paragraph = Swordfish::Node::Paragraph.new
      _node_parse_runs(node).each {|r| paragraph.append(r)}
      if node.xpath("./w:pPr/w:pStyle").length > 0
        style_id = node.xpath("./w:pPr/w:pStyle")[0]['w:val'].to_sym
        paragraph.style = @styles[style_id] if @styles[style_id]
      end
      paragraph
    end

    # Parse a list
    def _node_parse_list(node)
      # In Office OpenXML, a list is not a distinct element type, but rather a
      # specialized paragraph that references an abstract numbering scheme
      # and includes an indentation level. As a result, the build buffer
      # must be used to assemble the Swordfish::Node representation of the list,
      # since the only way to tell the list has been fully parsed is to encounter
      # a non-list element.

      # Handle paragraphs with no level, which represent multi-paragraph list items
      if node.xpath(".//w:numPr/w:ilvl").length.zero?
        para = Swordfish::Node::Paragraph.new
        _node_parse_runs(node).each {|r| para.append(r)}
        @buffer.last_list_item(:recurse => true).wrap_children(Swordfish::Node::Text, Swordfish::Node::Paragraph)
        @buffer.last_list_item(:recurse => true).append para
        return
      end

      # Get the list item's abstract numbering and level
      list_item = Swordfish::Node::ListItem.new
      _node_parse_runs(node).each {|r| list_item.append(r)}
      level = node.xpath(".//w:numPr/w:ilvl")[0]['w:val'].to_i
      numbering_scheme = node.xpath(".//w:numPr/w:numId")[0]['w:val'].to_i

      # If the build buffer is empty, this is a new list
      unless @buffer
        @buffer = Swordfish::Node::List.new
        @buffer.stylize @numbering[numbering_scheme][level].to_sym
        @buffer_initial_value = level # Lists may have an arbitrary initial level
      end

      # Compare the level of this list item to the bottommost node in
      # the build buffer to determine where in the hierarchy to add
      # this node (i.e., are we dealing with list nesting or not?)
      if @buffer.depth_of_final_node >= level || @buffer.children.empty?
        # Add sibling to existing list
        target = @buffer
        (level - @buffer_initial_value).times do
          target = target.last_list_item.nested_list
        end
        target.append list_item
      elsif @buffer.depth_of_final_node < level
        # Add new nested list
        target = @buffer
        (level - @buffer_initial_value- 1).times do
          target = target.last_list_item.nested_list
        end
        list = Swordfish::Node::List.new
        list.append list_item
        list.stylize @numbering[numbering_scheme][level].to_sym
        target.last_list_item.append list
      end
    end

    # Parse a table
    def _node_parse_table(node)
      table = Swordfish::Node::Table.new
      node.xpath("./w:tr").each do |row|
        table.append _node_parse_table_row(row)
      end
      table
    end

    # Parse a table row
    def _node_parse_table_row(node)
      row = Swordfish::Node::TableRow.new
      node.xpath('./w:tc').each do |cell|
        row.append _node_parse_table_cell(cell)
      end
      row
    end

    # Parse a table cell
    def _node_parse_table_cell(node)
      # In a Swordfish::Node::Table object, the number of table cells must equal the
      # total number of rows times the total number of columns; that is, even if
      # two cells are merged together, there must be a Swordfish::Node::TableCell for
      # each one. Merges are defined using the "merge_up" and "merge_left" properties.

      cell = Swordfish::Node::TableCell.new
      extra_cells = []

      # Get the inner content of the cell
      node.xpath("./w:p").each do |paragraph|
        cell.append _node_parse_paragraph(paragraph)
      end
      
      # Determine whether this cell spans multiple rows. In Office OpenXML,
      # a table cell is defined in every row, even if the cell is vertically-merged. The representation
      # of the merged cell within each row is given a vMerge property, with the topmost one also
      # having a vMerge value of "restart", and the others having no vMerge value.
      if node.xpath("./w:tcPr/w:vMerge").length > 0 && node.xpath("./w:tcPr/w:vMerge")[0]['w:val'].nil?
        cell.merge_up = true
      end

      # Determine whether this cell spans multiple columns. Unlike with vertical merges,
      # a horizontally-merged Office OpenXML cell is only defined once, but is given a gridSpan
      # property defining the number of columns it spans. Since Swordfish requires a cell for each
      # column, loop to generate the additional cells, and set their merge_left values appropriately.
      if node.xpath("./w:tcPr/w:gridSpan").length > 0
        node.xpath("./w:tcPr/w:gridSpan")[0]['w:val'].to_i.-(1).times do
          c = Swordfish::Node::TableCell.new
          c.merge_left = true
          extra_cells << c
        end
      end

      # Return the generated cell or cells
      if extra_cells.empty?
        return cell
      else
        return [cell] + extra_cells
      end
    end

  end
end
