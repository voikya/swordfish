require 'swordfish/document'
require 'swordfish/formats/docx/document'
require 'swordfish/formats/odt/document'

module Swordfish
  
  # Main entry point into the parser. Pass in a filepath and return a parsed document.
  def self.open(filepath, opts={})
    extension = (opts[:extension] || filepath.split('.').last).downcase.to_sym
    case extension
      when :docx
        Swordfish::DOCX::Document.open(filepath)
      when :odt
        Swordfish::ODT::Document.open(filepath)
      else
        raise UnsupportedFormatError, "'#{extension}' is not a recognized file format"
    end
  end

  class UnsupportedFormatError < LoadError
  end
end
