#!/usr/bin/env ruby
require './parametric_keyboard'
require 'rubyscad'
extend RubyScad

keymap = [
  # start ROW 0
  [[0.5,0.5],1, :stabilizers]
]

kb = ParametricKeyboard.new(
  width: 2,
  height: 2,
  keymap: keymap,
  include_cutouts: false
)
kb.plate.save_scad('test.scad')
