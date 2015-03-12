Simple Tomboy Server - v0.1.2
=============================

 THE AUTHOR OF THIS SOFTWARE IS NOT RELATED TO THE AUTHORS OF TOMBOY SOFTWARE

 Copyright (c) 2011-2014 Marcio Frayze David (mfdavid@gmail.com)
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 1. Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.


About this software
===================

Simple Tomboy Server is a software that allows you to read all notes 
created with the Tomboy software from anywhere in the world using a
web-browser.


How to use it
=============

Before you run this software, you must install Ruby Programming Language.

Start the server using the following command:
ruby tomboy-notes-server.rb

Open a web-browser and go to http://localhost:10002

Change "localhost" to your ip address to be able to access it from another
computer.


Compatibility
=============

This software was created and tested under Ubuntu 12 LTS and Ruby 2.1.5. 
It may not work on different distributions without some basic chances in the code.
Please, make sure the BASE_DIR variable is set correctly. Future versions will
be more clever about this.


Have Fun!
