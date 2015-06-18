# encoding: utf-8

require 'logger'
require 'nokogiri'

notes_directory = '/Users/mariano/Dropbox/Notes'
limit           = 15
query           = ARGV.empty? || ARGV.first == 'normalise,' ? nil : ARGV.first
Item            = Struct.new(:path, :title, :subtitle)

log = Logger.new 'worflow.log'
log.info "== Running with query: `#{query}` =="

# -----------------------------

# ls -ptU | grep -Ev '/'

# Busqueda
# find /Users/mariano/Dropbox/Notes -type f \( -name \*.md -o -name \*.txt \) -exec grep -l "infra" {} \+ | head -n10

# Latest
# find /Users/mariano/Dropbox/Notes -type f \( -name \*.md -o -name \*.txt \) -exec stat -f "%B %N" {} \; | sort -r | head -n10 | awk '{print $2}'

# -----------------------------


if query
  files = `find #{notes_directory} -type f \\( -name \*.md -o -name \*.txt \\) -exec grep -isrc "#{query}" {} \\+ | grep -v ':0$' | sort -nr -k2 -t: | head -n#{limit}`
    .split
    .map { |f| parts = f.force_encoding('UTF-8').split(':'); Item.new(parts.first, File.basename(parts.first), "#{parts.last} match#{'es' if parts.last.to_i > 1}") }
    # .sort {|a,b| File.ctime(a.path) <=> File.ctime(b.path) }
else
  files = `find #{notes_directory} -type f \\( -name \*.md -o -name \*.txt \\) -exec stat -f "%B %N" {} \\+ | sort -r | head -n#{limit} | awk '{print $2}'`
    .split
    .map { |f| Item.new(f, File.basename(f), File.ctime(f).strftime("%B %e, %Y at %I:%M %p")) }
end

# exit if files.empty?

# files.each do |f|
#   p f
# end

builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
  xml.items {
    files.each do |file|
      xml.item(arg: file.path, autocomplete: file.title) {
        xml.title(file.title)
        xml.subtitle(file.subtitle)
        xml.icon(type: 'fileicon') {
          xml.text(file.path)
        }
      }
    end
  }
end
puts builder.to_xml
