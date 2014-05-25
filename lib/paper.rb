require 'paper/document'
require 'paper/formats/docx'

module Paper
  def self.open(filepath)
    extension = filepath.split('.').last.downcase
    case extension
      when 'docx'
        Paper::DOCX.open(filepath)
      else
        raise UnsupportedFormatError
    end
  end

  class UnsupportedFormatError < LoadError
  end
end
