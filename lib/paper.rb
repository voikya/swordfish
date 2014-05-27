require 'paper/document'
require 'paper/formats/docx'

module Paper
  
  # Main entry point into the parser. Pass in a filepath and return a parsed document.
  def self.open(filepath)
    extension = filepath.split('.').last.downcase
    case extension
      when 'docx'
        Paper::DOCX.open(filepath)
      else
        raise UnsupportedFormatError, "'#{extension}' is not a recognized file format"
    end
  end

  class UnsupportedFormatError < LoadError
  end
end
