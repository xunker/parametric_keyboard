#!/usr/bin/env ruby
require './parametric_keyboard'
require 'rubyscad'
extend RubyScad

# http://www.keyboard-layout-editor.com/#/gists/d6352c2cd4161ceea3d5

# keymap = [
#   # start ROW 0
#   [[0,0],1], # esc
#   [[1,0],1], # 1
#   [[2,0],1], # 2
#   [[3,0],1], # 3
#   [[4,0],1], # 4
#   [[5,0],1], # 5
#   [[6,0],1], # 6
#   [[7,0],1], # 7
#   [[8,0],1], # 8
#   [[9,0],1], # 9
#   [[10,0],1], # 0
#   [[11,0],1], # -
#   [[12,0],1], # =
#   [[13,0],1.5], # bksp
#   # start ROW 1
#   [[  0,1],1.5], # tab
#   [[1.5,1],1], # q
#   [[2.5,1],1], # w
#   [[3.5,1],1], # e
#   [[4.5,1],1], # r
#   [[5.5,1],1], # t
#   [[6.5,1],1], # y
#   [[7.5,1],1], # u
#   [[8.5,1],1], # i
#   [[9.5,1],1], # o
#   [[10.5,1],1], # p
#   [[11.5,1],1], # [
#   [[12.5,1],1], # ]
#   [[13.5,1],1], # \
#   # start ROW 2
#   [[   0,2],1.75], # ctrl
#   [[1.75,2],1], # a
#   [[2.75,2],1], # s
#   [[3.75,2],1], # d
#   [[4.75,2],1], # f
#   [[5.75,2],1], # g
#   [[6.75,2],1], # h
#   [[7.75,2],1], # j
#   [[8.75,2],1], # k
#   [[9.75,2],1], # l
#   [[10.75,2],1], # ;
#   [[11.75,2],1], # '
#   [[12.75,2],1.75], # enter
#   # start ROW 3
#   [[   0,3],2.25], # lshift
#   [[2.25,3],1], # z
#   [[3.25,3],1], # x
#   [[4.25,3],1], # c
#   [[5.25,3],1], # v
#   [[6.25,3],1], # b
#   [[7.25,3],1], # n
#   [[8.25,3],1], # m
#   [[9.25,3],1], # ,
#   [[10.25,3],1], # .
#   [[11.25,3],1], # /
#   [[12.25,3],1.25], # up
#   [[13.5,3],1], # rshift
#   # start ROW 4
#   [[0,4],1], # fn
#   [[1,4],1], # `
#   [[2,4],1.25], # lalt
#   [[3.25,4],1.25], # lcmd
#   [[4.5,4],2.75, :stabilizers], # space 1
#   [[7.25,4],2, :stabilizers], # space 2
#   [[9.25,4],1.25], # rcmd
#   [[10.5,4],1], # fn
#   [[11.5,4],1], # left
#   [[12.5,4],1], # down
#   [[13.5,4],1], # right
# ];

keymap = ParametricKeyboard.keymap_from_json(File.new('./Recycler-V21.kbd.json').read)

mounting_holes = [
  [ 1, 0.1 ],
  [ 2, 0.1 ],
  [ 3, 0.1 ],
  [ 4, 0.1 ],
  [ 5, 0.1 ],
  [ 6, 0.1 ],
  # [ 7, 0.1 ], # split
    [ 6.93, 0.1 ], # split
  [ 8, 0.1 ],
  [ 9, 0.1 ],
  [ 10, 0.1 ],
  [ 11, 0.1 ],
  [ 12, 0.1 ],
  [ 13.10, 0.1 ],
  [ 14.4, 0.1 ],

  [ 0.15, 1 ],
  [ 0.15, 2 ],
  [ 0.15, 3 ],
  [ 0.15, 4 ],

  [ 2.5, 1, :beefy ],
  [ 4.5, 1, :beefy ],
  [ 9.5, 1, :beefy ],
  [ 11.5, 1, :beefy ],
  [ 14.4, 1 ],

  [ 1.4, 2, :beefy ],
  [ 3.5, 2, :beefy ],
  # [ 5.5, 2, :beefy ],
  [ 8.75, 2, :beefy ],
  [ 10.75, 2, :beefy ],
  [ 12.75, 2, :beefy ],
  [ 14.4, 2 ],

  [ 2.75, 3, :beefy ],
  [ 4.75, 3, :beefy ],
  [ 9.75, 3, :beefy ],
  [ 11.75, 3, :beefy ],
  [ 14.4, 3 ],

  [ 2.15, 4, :beefy ],
  [ 4.25, 4, :beefy ],
  [ 6.25, 4, :beefy ],
  [ 9.25, 4, :beefy ],
  [ 11.25, 4, :beefy ],
  [ 13.5, 4, :beefy ],
  [ 14.4, 4 ],

  [ 1, 4.9 ],
  [ 2.05, 4.9 ],
  [ 3.25, 4.9 ],
  [ 4.75, 4.9 ],
  [ 9.25, 4.9 ],
  [ 10.45, 4.9 ],
  [ 11.5, 4.9 ],
  [ 12.5, 4.9 ],
  [ 13.5, 4.9 ],

  # split - left side
  [ 6.4, 1 ],
  [ 6.4, 2 ],
  [ 6.65, 3 ],
  [ 7.1, 4 ],
  [ 7.1, 4.9 ],
  # split - right side
  [ 7.1, 1 ],
  [ 6.85, 2 ],
  [ 7.35, 3 ],
  [ 7.35, 4 ],
  [ 7.35, 4.9 ],

]

right_truncations = [
  [[7,0],:right],
  [[6.5,1],:right],
  [[6.75,2],:right],
  [[7.25,3],:right],
  [[7.25,4],:right]
]

left_truncations = [
  [[7,0],:left], # 6
  [[6.5,1],:left], # t
  [[6.75,2],:left], # g
  [[7.25,3],:left], # b
  [[7.25,4],:left], # space 1
]

# kb = ParametricKeyboard.new(
#   width: 14.5,
#   height: 5,
#   keymap: keymap,
#   truncations: left_truncations,
#   include_cutouts: false
# )
# puts kb.plate.to_scad
# kb.plate.save_scad('split_board.scad')
# kb.case.save_scad('split_board.scad')
# kb.case.to_scad do |the_case|
#    echo("before")
#    the_case
#    echo("after")
# end

# To generate two pieces on the same scad, translated
require 'stringio'

original_stdout = $stdout

new_stdout = StringIO.new
$stdout = new_stdout

# union do
   # kb = ParametricKeyboard.new(
   #   width: 14.5,
   #   height: 5,
   #   keymap: keymap,
   #   truncations: right_truncations,
   #   include_cutouts: false
   # )
   # kb.case.to_scad

#    translate(x: kb.case_wall_thickness) do
#       kb = ParametricKeyboard.new(
#         width: 14.5,
#         height: 5,
#         keymap: keymap,
#         truncations: left_truncations,
#         include_cutouts: false
#       )
#       kb.case.to_scad
#    end
# end

## Stacked

# union do
#    kb = ParametricKeyboard.new(
#      width: 14.5,
#      height: 5,
#      keymap: keymap,
#      truncations: right_truncations,
#      include_cutouts: false
#    )
#    kb.case.to_scad

#    translate(z: kb.case_height) do
      kb = ParametricKeyboard.new(
        # width: 14.5,
        # height: 5,
        keymap: keymap,
        cavity_height: 7,
        # truncations: right_truncations,
        # truncations: left_truncations,
        include_cutouts: false,
        mounting_holes: mounting_holes,
        support_holes: [
          [1.25,3.8], [1.25,4.1], [1.25,4.4],
          [5.25,3.8], [5.25,4.1], [5.25,4.4],
          [7.9,3.8], [7.9,4.1], [7.9,4.4],
          [13.0,3.8], [13.0,4.1], [13.0,4.4]
        ],
        underside_openings: [
          {
            x: 3,
            y: 3.5,
            width: 1,
            length: 1.25,
            screw_holes: true
          },
          {
            x: 10,
            y: 3.5,
            width: 1,
            length: 1.25,
            screw_holes: true
          }

        ],
        plate_thickness: 2.8
      )
      # kb.plate.to_scad
      kb.case.to_scad
#    end

#    kb = ParametricKeyboard.new(
#      width: 14.5,
#      height: 5,
#      keymap: keymap,
#      truncations: left_truncations,
#      include_cutouts: false
#    )

#    translate(x: 12) do
#       kb.case.to_scad
#       translate(z: kb.case_height) do
#          kb = ParametricKeyboard.new(
#            width: 14.5,
#            height: 5,
#            keymap: keymap,
#            truncations: left_truncations,
#            include_cutouts: false
#          )
#          kb.plate.to_scad
#       end
#    end

# end

File.open('split_board.scad', 'w') do |f|
   f.puts new_stdout.string
end

$stdout = original_stdout
