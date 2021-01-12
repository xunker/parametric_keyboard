#!/usr/bin/env ruby
require './parametric_keyboard'
require 'rubyscad'
extend RubyScad

# http://www.keyboard-layout-editor.com/#/gists/360d9cddb622786ef1f7382acab8deb4

keymap = ParametricKeyboard.keymap_from_json(File.new('./redd.json').read)

mounting_holes = []

# add top edge holes
mounting_holes += 1.upto(6).map{|x_pos| [ x_pos, 0.1 ]}
mounting_holes += 8.upto(13).map{|x_pos| [ x_pos, 0.1 ]}

# left split holes
mounting_holes << [ 7-0.1, 0.1 ]
mounting_holes += 1.upto(4).map{|y_pos| [ 7-0.1, y_pos ]}
# right split holes
mounting_holes << [ 7+0.1, 0.1 ]
mounting_holes += 1.upto(4).map{|y_pos| [ 7+0.1, y_pos ]}

# left side holes
mounting_holes += 1.upto(4).map{|y_pos| [ 0.15, y_pos ]}

# right side holes
mounting_holes += 1.upto(4).map{|y_pos| [ 14-0.15, y_pos ]}

# bottom edge holes
mounting_holes += 1.upto(3).map{|x_pos| [ x_pos, 5-0.1 ]}
mounting_holes << [ 4.5, 5-0.1 ] # left of space
mounting_holes << [ 7-0.1, 5-0.1 ] # right of space, before split

mounting_holes << [ 7+0.1, 5-0.1 ] # right of space, after split
mounting_holes += 8.upto(13).map{|x_pos| [ x_pos, 5-0.1 ]}

# holes in the middle, fewer, larger diameter supports
mounting_holes += 2.step(13, 2).map{|x_pos| [ x_pos, 2, :beefy ]}
mounting_holes += 4.step(13, 2).map{|x_pos| [ x_pos, 4, :beefy ]}

right_truncations = 5.times.map{|row_num| [[7, row_num],:right]}
left_truncations = 5.times.map{|row_num| [[7, row_num],:left]}

# To generate two pieces on the same scad, translated
require 'stringio'

original_stdout = $stdout

new_stdout = StringIO.new
$stdout = new_stdout

File.open('redd.scad', 'w') do |f|
  [
    [-10, right_truncations],
    [+10, left_truncations],
    # [0, []]
  ].each do |x_offset, truncations|
    translate(x: x_offset) do
        kb = ParametricKeyboard.new(
          keymap: keymap,
          cavity_height: 7,
          truncations: truncations,
          include_cutouts: false,
          mounting_holes: mounting_holes,
          support_holes: [
            [1.25,3.8], [1.25,4.05], [1.25,4.3],
            [5.25,3.8], [5.25,4.05], [5.25,4.3],
            [7.9,3.8], [7.9,4.05], [7.9,4.3],
            [13.0,3.8], [13.0,4.05], [13.0,4.3]
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

        # translate(z: kb.case_height + 10) do
        translate(y: 8*14) do
          kb.plate.to_scad
        end

        kb.case.to_scad
    end
  end

  f.puts new_stdout.string
end

$stdout = original_stdout
