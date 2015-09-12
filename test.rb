#!/usr/bin/env ruby
require './parametric_keyboard'
require 'rubyscad'
extend RubyScad

keymap = [
  # start ROW 0
  [[1,1],1, :stabilizers]
]

kb = ParametricKeyboard.new(
  width: 3,
  height: 3,
  keymap: keymap,
  include_cutouts: false
)
kb.plate.save_scad('test.scad')
