# Paper::Stylesheet represents formatting applied to a node

module Paper
  class Stylesheet
    
    # Define all supported values here
    SUPPORTED_STYLES = [
      # Inline styles
      :bold, :italic, :underline, :superscript, :subscript, :strikethrough,
      # List enumeration styles
      :bullet, :decimal, :lowerLetter, :lowerRoman
    ]

    # Initialize a stylesheet with an optional list of styles
    def initialize(styles)
      @styles = []
      merge styles
    end

    # Take a style or list of styles and add them to an existing stylesheet
    def merge(styles)
      styles = [styles] unless styles.is_a?(Array)
      @styles |= styles.select{|s| SUPPORTED_STYLES.include?(s)}
    end
    
    # For each supported style, define a boolean method to check its presence
    # (i.e., :bold?, :italic?, etc.)
    SUPPORTED_STYLES.each do |style|
      define_method "#{style}?".to_sym do
        has_style?(style)
      end
    end

    private

    # Check if a style is included in a stylesheet
    def has_style?(style)
      @styles.include? style
    end

  end
end
