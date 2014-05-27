require 'swordfish/document'
require 'swordfish/formats/docx'

module Swordfish
  
  # Main entry point into the parser. Pass in a filepath and return a parsed document.
  def self.open(filepath)
    extension = filepath.split('.').last.downcase
    case extension
      when 'docx'
        Swordfish::DOCX.open(filepath)
      else
        raise UnsupportedFormatError, "'#{extension}' is not a recognized file format"
    end
  end

  class UnsupportedFormatError < LoadError
  end
end
