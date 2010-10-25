#!/bin/env ruby
# -*- coding: utf-8 -*-

require 'webrick'
require 'webrick/httpproxy'
require 'uri'
require 'kconv'
require 'stringio'
require 'zlib'

handler = Proc.new() do |req, res|
  if res['content-type'] =~ %r!text/html!
    body = res.body
    if res.header["content-encoding"] == "gzip"
      Zlib::GzipReader.wrap(StringIO.new(res.body)){|gz| body = gz.read}
      res.header.delete("content-encoding")
      res.header.delete("content-length")
    end

    print body
    utf_str = body.toutf8
    utf_str.gsub!(/。/, 'にょ。')
    code = Kconv.guess(body)
    res.body = utf_str.kconv(code, Kconv::UTF8)
  end
end

s = WEBrick::HTTPProxyServer.new(
  :BindAddress => '127.0.0.1',
  :Port => 8080,
  :Logger => WEBrick::Log::new( $stdout, WEBrick::Log::DEBUG ),
  :ProxyVia => false,
  :ProxyContentHandler => handler
  )

Signal.trap( 'INT' ) do
  s.shutdown
end

s.start
