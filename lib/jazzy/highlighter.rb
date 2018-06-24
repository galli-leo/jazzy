require 'rouge'
require 'jazzy/sourcekitten'

module Jazzy
  # This module helps highlight code
  module Highlighter
    Rouge::Token::Tokens.token(:StartUSRLink, "usrs")
    Rouge::Token::Tokens.token(:EndUSRLink, "usre")

    class Formatter < Rouge::Formatters::HTML
      def initialize(language)
        @language = language
        super()
      end

      def stream(tokens, &b)
        yield "<pre class=\"highlight #{@language}\"><code>"
        tokens.each { |tok, val|
          if tok == :StartUSRLink
            if val[1] != nil
              yield "<a href=\"#{val[1]}\" target=\"_blank\">"
            else
              yield "<a href=\"#{ELIDED_AUTOLINK_TOKEN}#{val[0]}#{ELIDED_AUTOLINK_TOKEN}\">"
            end
          elsif tok == :EndUSRLink
            yield "</a>"
          else
            yield span(tok, val)
          end

        }
        yield "</code></pre>\n"
      end
    end

    class SourceKitLexer < Rouge::Lexers::Swift
      prepend :root do
        rule /(.)?<USRLINK\susr\s?=\s?"(.*?)"\s?(\surl\s?=\s?"(.*?)"\s?)?>(.*?)<\s?\/USRLINK\s?>/ do |m|
          if m[1] != nil
            token Punctuation, m[1]
          end
          token :StartUSRLink, [m[2], m[4]]
          token Keyword::Type, m[5]
          token :EndUSRLink, m[2]
        end
      end
    end

    # What Rouge calls the language
    def self.default_language
      if Config.instance.objc_mode
        'objective_c'
      else
        SourceKitLexer.new()
      end
    end

    def self.highlight(source, language = default_language)
      source && Rouge.highlight(source, language, Formatter.new(language))
    end
  end
end
