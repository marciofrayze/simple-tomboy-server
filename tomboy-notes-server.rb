#!/usr/bin/ruby

# Simple Tomboy Server version 0.1.2
# THE AUTHOR OF THIS SOFTWARE IS NOT RELATED TO THE AUTHORS OF TOMBOY SOFTWARE

# Copyright (c) 2011-2014 Marcio Frayze David (mfdavid@gmail.com)
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

require 'gserver'

# This is the default directory for tomboy note files
# If you are using an old version of tomboy, yoy may need to change this to "/.tomboy/"
@@BASE_DIR = ENV['HOME'] + '/.local/share/tomboy/'

class TomBoyServer < GServer

	# Getting and parsing the user command to get the name of the note the user wants to access	
	def parse_note_name_from_request(io)
    parameters = io.gets
    note_name = parameters[5,parameters.length-16].strip
	end

	# Main method used by gserver, called when a new http request is received
  def serve(io)
		note_name = parse_note_name_from_request(io)   		
		return '' if note_name == 'favicon.ico' 			# Ignore request if it is for favicon.ico		
		log "Receive request for note: #{note_name}"  # logs request into console

		# Sending back to the user some basic http header response
		io.puts(basic_http_response_header)

    # Processing and generating the actual user response    
    user_response = html_head_code
    user_response += simple_top_menu if is_note_name_valid?(note_name)	# Includes a simple top menu if not in the listing page
		user_response += page_content(note_name)														# Includes the note content or list of notes
  	user_response += css_code 																					# Inject some css
    user_response += html_tail_code 																		# HTML tail code      
		user_response = optimize_html_code(user_response)										# Optimizing the final html code
	
		# Sending page back to the user
    io.puts(user_response)
		log "Done processing request"
  end

	def page_content(note_name)
		page_body = '<body>'

    # Checking if user is accessing a page. If so, read the file and print it to the output
		# If no page was requested (or the page requested was not found), 
		# create a menu with links to all the notes
    if is_note_name_valid?(note_name)
			log "Returning content from note: #{note_name}"
	    page_body += load_note(note_name)
    else
			log 'Returning menu...'
	    page_body += create_menu			
    end
		page_body += '</body>'

		return page_body
	end

	# Strip out blank lines and useless tags
	def optimize_html_code(html_code)
    html_code = html_code.strip.gsub(/\n/,'') 						# Strip out blank lines
    html_code.gsub!(/(<br \/>){3,}/, '<br /><br />')			# Avoid repetitive break lines
    html_code.gsub!(/<\/h1>(<br \/>){2,}/, '</h1><br />')	# Avoid repetitive break lines again
		return html_code
	end

  # Load (and parse to html) a note - this code is very messy, should be refactored
  def load_note(note_name)
    lines = IO.readlines(@@BASE_DIR + '/' + note_name + '.note')
    lines = delete_non_relevant_lines(lines)
    user_response = ''
		# Reading note lines
    lines.each { |line|
      # Translating the links (get the title of the page and then recover the name of the file to create the link)
      start_link_index = line.index('<link:internal>')
      final_link_index = line.index('</link:internal>')
      while(start_link_index != nil  and final_link_index != nil)         # While there is still links to convert
        start_link_index = line.index('<link:internal>') + 15
        title = line[start_link_index, final_link_index-start_link_index] # Parsing the title of the link
        page = get_page_with_title(title)
        if page != 'Not_Found'
          page = page[@@BASE_DIR.length, 36]
          line.sub!('<link:internal>', '<a href=' + page + '>')
          line.sub!('</link:internal>', '</a>')
        else # There is a link, but it's not valid! So we ignore it.
          line.sub!('<link:internal>', '')
          line.sub!('</link:internal>', '')
        end
        final_link_index = line.index('</link:internal>') # Checking if there is still more links in this line
      end
      user_response += convert_tomboy_to_html(line + '<br />')
    }
    return user_response
  end

  # Creates the default menu listing all the notes
  def create_menu	
    menu = '<h1>Listing all notes</h1>'
    tomboy_notes = list_all_tomboy_notes
    tomboy_notes.each { | note |
      # Get the name of the note
      lines = IO.read(note)
      title_index = lines.index('<title>') + 7
      title_end_index = lines.index('</title>')
      note = note[@@BASE_DIR.length, 36]
      menu += "<a href=#{note}>"
      menu += convert_tomboy_to_html(lines[title_index, title_end_index-title_index]) + '</a><br />'
    }
    return menu
  end

  # Ignore non-relevant lines (is there a better way to do this?)
  def delete_non_relevant_lines(lines)
    lines[0]   = ''
    lines[3]   = ''
    lines[-1]  = ''
    lines[-2]  = ''
    lines[-3]  = ''
    lines[-4]  = ''
    lines[-5]  = ''
    lines[-6]  = ''
    lines[-7]  = ''
    lines[-8]  = ''
    lines[-9]  = ''
    lines[-10] = ''
    return lines
  end

  # Converting tomboy xml code to html
	# I know, this code is very very ugly... but it works :) fell free to refactor it.
  def convert_tomboy_to_html(tomboy_code)
    tomboy_code.gsub!('<title>', '<h1>')
    tomboy_code.gsub!('</title>', '</h1>')
    tomboy_code.gsub!('<bold>', '<b>')
    tomboy_code.gsub!('</bold>', '</b>')
    tomboy_code.gsub!('<italic>', '<i>')
    tomboy_code.gsub!('</italic>', '</i>')
    tomboy_code.gsub!('<size:small>', '<font size=-1>')
    tomboy_code.gsub!('<size:large>', '<font size=+2>')
    tomboy_code.gsub!('<size:huge>', '<font size=+4>')
    tomboy_code.gsub!(/<\/size:[^>]+>/, '</font>')
    # Erasing all others useless xml tags
    tomboy_code.gsub!(/<?xml version=[^>]+>/, '')
    tomboy_code.gsub!(/<note version=[^>]+>/, '')
    tomboy_code.gsub!(/<text xml:space=\"preserve\"><note-content version=[^>]+>/, '')
    tomboy_code.gsub!('<title>', '<h1>')
    tomboy_code.gsub!('</title>', '</h1>')
    tomboy_code.gsub!('</note-content></text>', '')
    tomboy_code.gsub!('<link:internal>', '')  # it should be replaced already, just in case
    tomboy_code.gsub!('</link:internal>', '') # it should be replaced already, just in case    
    return tomboy_code.to_s
  end

  # Return the name of all tomboy notes files
  def list_all_tomboy_notes
    return Dir.glob(@@BASE_DIR + '*.note')
  end

  # Checks if the name of a note is valid (constains 36 standard chars and exists)
  def is_note_name_valid?(note_name)

    return false if note_name.size != 36

    note_name.each_byte { |c|
      return false if not 'qwertyuiopasdfghjklzxcvbnm-1234567890'.include?(c.chr)
    }

    # Checking if file exists
		return File.exist?(@@BASE_DIR + note_name + '.note')
  end

  # Given a title, returns the respective note file name
  def get_page_with_title(title)
    tomboy_notes = list_all_tomboy_notes
    tomboy_notes.each { | note |
      # Get the name of the note
      lines = IO.read(note)
      title_index = lines.index('<title>') + 7
      title_end_index = lines.index('</title>')
      current_title = lines[title_index, title_end_index-title_index]
      if current_title == title
        return note
      end
    }
    return 'Not_Found'
  end

	def html_head_code
		'<html><title>Simple Tomboy Server - ' + ENV['USER'] + '</title></head>'
	end

	def basic_http_response_header
		"HTTP/1.1 200/OK\r\nContent-type:text/html ; charset=UTF-8\r\n\r\n"
	end

	# Just some final html code closing tags, etc.
	def html_tail_code
		'<br /><hr>Powered by <a href="https://github.com/mfdavid/Simple-Tomboy-Server">Simple Tomboy Server</a></body></html>'
	end

	# Some CSS code that will be injected in the page to try and make it look less terrible
	def css_code
		'<style>body { background-color: #F0F0F0; margin:5% 15%; padding:0px; } a { text-decoration: none; color: #0000FF } a:hover { color: #0066CC; }</style>'		
	end

	# Just a very simple top menu
	def simple_top_menu
		'<a href = "javascript:history.back()"><< Back to previous page</a> | <a href=.>Main menu</a>' 
	end

	# For now, just logging the messages on console
	def log(message)
		puts Time.now.to_s + ' ' + message.to_s
	end

end

# Starts the server :-)
server = TomBoyServer.new(10002, nil)
server.start
puts 'Server started.'
server.join
