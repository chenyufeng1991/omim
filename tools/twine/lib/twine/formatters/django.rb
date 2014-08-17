module Twine
  module Formatters
    class Django < Abstract
      FORMAT_NAME = 'django'
      EXTENSION = '.po'
      DEFAULT_FILE_NAME = 'strings.po'

      def self.can_handle_directory?(path)
      Dir.entries(path).any? { |item| /^.+\.po$/.match(item) }
      end

      def default_file_name
        return DEFAULT_FILE_NAME
      end

      def determine_language_given_path(path)
          path_arr = path.split(File::SEPARATOR)
          path_arr.each do |segment|
              match = /(..)\.po$/.match(segment)
              if match
                  return match[1]
              end
          end

        return
      end

      def read_file(path, lang)
        comment_regex = /#.? *"(.*)"$/
        key_regex = /msgid *"(.*)"$/
        value_regex = /msgstr *"(.*)"$/m

        encoding = Twine::Encoding.encoding_for_path(path)
        sep = nil
        if !encoding.respond_to?(:encode)
          # This code is not necessary in 1.9.3 and does not work as it did in 1.8.7.
          if encoding.end_with? 'LE'
            sep = "\x0a\x00"
          elsif encoding.end_with? 'BE'
            sep = "\x00\x0a"
          else
            sep = "\n"
          end
        end

        if encoding.index('UTF-16')
          mode = "rb:#{encoding}"
        else
          mode = "r:#{encoding}"
        end

        File.open(path, mode) do |f|
          last_comment = nil
          while line = (sep) ? f.gets(sep) : f.gets
            if encoding.index('UTF-16')
              if line.respond_to? :encode!
                line.encode!('UTF-8')
              else
                require 'iconv'
                line = Iconv.iconv('UTF-8', encoding, line).join
              end
            end
            if @options[:consume_comments]
               comment_match = comment_regex.match(line)
               if comment_match
                   comment = comment_match[1]
               end
            else
                comment = nil
            end
            key_match = key_regex.match(line)
            if key_match
                key = key_match[1].gsub('\\"', '"')
            end
            value_match = value_regex.match(line)
            if value_match
                value = value_match[1].gsub(/"\n"/, '').gsub('\\"', '"')
            end


            if key and key.length > 0 and value and value.length > 0
                set_translation_for_key(key, lang, value)
                if comment and comment.length > 0 and !comment.start_with?("--------- ")
                    set_comment_for_key(key, comment)
                end
                comment = nil
            end

          end
        end
      end

      def write_file(path, lang)
        default_lang = @strings.language_codes[0]
        encoding = @options[:output_encoding] || 'UTF-8'
        File.open(path, "w:#{encoding}") do |f|
          f.puts "##\n # Django Strings File\n # Generated by Twine #{Twine::VERSION}\n # Language: #{lang}\n "
          @strings.sections.each do |section|
            printed_section = false
            section.rows.each do |row|
              if row.matches_tags?(@options[:tags], @options[:untagged])
                f.puts ''
                if !printed_section
                  if section.name && section.name.length > 0
                    f.print "#--------- #{section.name} ---------#\n\n"
                  end
                  printed_section = true
                end

                basetrans = row.translated_string_for_lang(default_lang)

                key = row.key
                key = key.gsub('"', '\\\\"')

                value = row.translated_string_for_lang(lang, default_lang)
                if value
                  value = value.gsub('"', '\\\\"')

                  comment = row.comment

                  if comment
                     comment = comment.gsub('"', '\\\\"')
                  end

                  if comment && comment.length > 0
                    f.print "#. #{comment} \n"
                  end

                  if basetrans && basetrans.length > 0
                    f.print "# base translation: \"#{basetrans}\"\n"
                  end

                  f.print "msgid \"#{key}\"\n"
                  f.print "msgstr \"#{value}\"\n"
                end
              end
            end
          end
        end
      end
    end
  end
end