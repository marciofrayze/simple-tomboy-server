#!/usr/bin/ruby1.8

# Simple Tomboy Server version 0.1
# THE AUTHOR OF THIS SOFTWARE IS NOT RELATED TO THE AUTHORS OF TOMBOY SOFTWARE

# Copyright (c) 2011 Marcio Frayze David (mfdavid@gmail.com)
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

class TomBoyServer < GServer

  # This is the default directory for tomboy files
  @@BASE_DIR = ENV['HOME'] + "/.tomboy/"

  def serve(io)
    # Getting and parsing the user command to get the name of the note the user wants to access
    parameters = io.gets
    note_name = parameters[5,parameters.length-16].strip

    # Writing default http protocol and some basic html code
    io.puts "HTTP/1.1 200/OK\r\nContent-type:text/html ; charset=UTF-8\r\n\r\n"    
    user_response = "<title>Tomboy - Server</title></head><body>"

    # Checking if user is accessing a page. If so, read the file and print it to the output
    if note_name != '' and note_name!='/' and is_note_name_safe?(note_name)
	    user_response += load_note(note_name)
    # If no page was requested, create a menu with links to all the notes
    else
	    user_response += create_menu()
    end

    # HTML tail code
    user_response += "<br /><hr>Powered by Simple Tomboy Server"
    user_response += "</body></html>"

    # Optimizing the final html code   
    user_response = user_response.strip.gsub(/\n/,'') 		# Strip out blank lines
    user_response.gsub!(/(<br \/>){3,}/, '<br /><br />')	# Avoid repetitive break lines
    user_response.gsub!(/<\/h1>(<br \/>){2,}/, '</h1><br />')	# Avoid repetitive break lines
    io.puts(user_response)
  end

  # Load (and parse to html) a note
  def load_note(note_name)
    lines = IO.readlines(@@BASE_DIR + "/" + note_name + ".note")
    lines = delete_non_relevant_lines(lines)
    user_response = "<a href = \"javascript:history.back()\"><< Back to previous page</a> | <a href=.>Main menu</a>" # Simple menu
    lines.each { |line|
      #Translating the links (get the title of the page and then recover the name of the file to create the link)
      start_link_index = line.index('<link:internal>')
      final_link_index = line.index('</link:internal>')
      while(start_link_index != nil  and final_link_index != nil)
        start_link_index = line.index('<link:internal>') + 15
        title = line[start_link_index, final_link_index-start_link_index]
        page = get_page_with_title(title)
        if page != 'Not_Found'
          page = page[@@BASE_DIR.length, 36]
          line.sub!('<link:internal>', '<a href=' + page + ">")
          line.sub!('</link:internal>', '</a>')
        else
          line.sub!('<link:internal>', '')
          line.sub!('</link:internal>', '')
        end
        final_link_index = line.index('</link:internal>')
      end
      user_response += convert_tomboy_to_html(line + "<br />")
    }
    return user_response
  end

  # Creates the default menu listing all the notes
  def create_menu	
    menu = "<h1>Listing all notes</h1>"
    tomboy_notes = list_all_tomboy_notes
    tomboy_notes.each { | note |
      # get the name of the note
      lines = IO.read(note)
      title_index = lines.index("<title>") + 7
      title_end_index = lines.index("</title>")
      note = note[@@BASE_DIR.length, 36]
      menu += "<a href=" + note + ">"
      menu += convert_tomboy_to_html(lines[title_index, title_end_index-title_index]) + "</a><br />"
    }
    return menu
  end

  # Ignore non-relevant lines
  def delete_non_relevant_lines(lines)
    lines[0] = ''
    lines[3] = ''
    lines[-1] = ''
    lines[-2] = ''
    lines[-3] = ''
    lines[-4] = ''
    lines[-5] = ''
    lines[-6] = ''
    lines[-7] = ''
    lines[-8] = ''
    lines[-9] = ''
    lines[-10] = ''
    return lines
  end

  # I know, this code is very very ugly.. but I'm too lazy to care :) fell free to refactor it.
  def convert_tomboy_to_html(tomboy_code)
    tomboy_code.gsub!('<?xml version="1.0" encoding="utf-8"?>', '')
    tomboy_code.gsub!('<note version="0.3" xmlns:link="http://beatniksoftware.com/tomboy/link" xmlns:size="http://beatniksoftware.com/tomboy/size" xmlns="http://beatniksoftware.com/tomboy">', '')
    tomboy_code.gsub!('<title>', '<h1>')
    tomboy_code.gsub!('</title>', '</h1>')
    tomboy_code.gsub!('<text xml:space="preserve"><note-content version="0.1">', '')
    tomboy_code.gsub!('</note-content></text>', '')
    tomboy_code.gsub!('<link:internal>', '')  # it should be replaced already, just in case
    tomboy_code.gsub!('</link:internal>', '') # it should be replaced already, just in case
    tomboy_code.gsub!('<bold>', '<b>')
    tomboy_code.gsub!('</bold>', '</b>')
    tomboy_code.gsub!('<italic>', '<i>')
    tomboy_code.gsub!('</italic>', '</i>')
    tomboy_code.gsub!('<size:small>', '<font size=-1>')
    tomboy_code.gsub!('</size:small>', '</font>')
    tomboy_code.gsub!('<size:large>', '<font size=+2>')
    tomboy_code.gsub!('</size:large>', '</font>')
    tomboy_code.gsub!('<size:huge>', '<font size=+4>')
    tomboy_code.gsub!('</size:huge>', '</font>')
    return tomboy_code.to_s
  end

  # Return the name of all tomboy notes files
  def list_all_tomboy_notes
    return Dir.glob(@@BASE_DIR + "*.note")
  end

  # Checks if the name of a note is safe (constains 36 standard chars)
  def is_note_name_safe?(note_name)
    if note_name.size!=36
      return false
    end

    note_name.each_byte { |c|
      unless "qwertyuiopasdfghjklzxcvbnm-1234567890".include?(c)
        return false
      end
    }

    #checking if file exists
    if File.exist?(@@BASE_DIR + note_name + ".note")
      return true
    end

    return false
  end

  # Given a title, returns the respective note file name
  def get_page_with_title(title)
    tomboy_notes = list_all_tomboy_notes
    tomboy_notes.each { | note |
      # get the name of the note
      lines = IO.read(note)
      title_index = lines.index("<title>") + 7
      title_end_index = lines.index("</title>")
      current_title = lines[title_index, title_end_index-title_index]
      if current_title == title
        return note
      end
    }
    return "Not_Found"
  end
end

# Starts the server :-)
server = TomBoyServer.new(10002, nil)
server.start
server.join