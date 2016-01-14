#!/usr/bin/env ruby
require './parametric_keyboard'
require 'rubyscad'
extend RubyScad

# Invalid truncation test

# keymap = [
#   # start ROW 0
#   [[0.5,0.5],1, :stabilizers],
#   [[0.5,1.5],1]
# ]

# kb = ParametricKeyboard.new(
#   width: 3,
#   height: 2,
#   keymap: keymap,
#   include_cutouts: false,
#   truncations: [[[2,1.5],:right]]
# )
# # kb.plate.save_scad('test.scad')
# kb.case.save_scad('test.scad')


keymap = [
  # start ROW 0
  [[0.25,0.25],1]
]

mounting_holes = [
  [ 0.1, 0.1 ],
  [ 1.4, 0.1 ],
  [ 0.1, 1.4 ],
  [ 1.4, 1.4 ],
]

kb = ParametricKeyboard.new(
  width: 1.5,
  height: 1.5,
  keymap: keymap,
  mounting_holes: mounting_holes,
  include_cutouts: false,
  cavity_height: 8,
)
# kb.plate.save_scad('test.scad')
kb.case.save_scad('test.scad')