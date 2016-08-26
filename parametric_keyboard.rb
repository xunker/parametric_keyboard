require 'rubyscad'

class ParametricKeyboard
  attr_reader :keymap, :width, :height, :plate_thickness,
    :key_unit_size, :key_hole_size,
    :cutout_width, :cutout_height, :include_cutouts,
    :truncations,
    :cavity_height, :case_floor_thickness, :case_wall_thickness, :case_height,
    :mounting_hole_diameter, :mounting_holes

  # `options` hash keys.
  #
  # Required:
  # keymap  Map of the keys. Can be set later with `#keymap=`
  #
  # Optional:
  # width   Width of board in units of `key_unit_size`. Can be float. Default is automatically calculated from map.
  # height  Height of the board in units of `key_unit_size`. Can be float. Default is automatically calculated from map.
  # plate_thickness Thickness of plate in mm. Default: 1.4
  # key_unit_size   Square length of space for a single key unit in mm. Default: 19.05
  # key_hole_size   Square length of cutout for switch in mm. Default: 14
  # cutout_height   Height of switch clasp cutouts in mm. Default: 3
  # cutout_width    Width of switch clasp cutouts in mm. Default: 1
  # include_cutouts Include the clasp cutouts? Default: true
  # mounting_hole_diameter  Diameter in mm of mounting holes.  Default: 1.5
  # truncations     Truncate rows to create partial, non-square plates. Can be set later.
  # cavity_height   Interior height of empty space in lower case. Default: 8
  # case_floor_thickness  Thickness of lower case floor. Default: 1
  # case_wall_thickness   Thickness of lower case walls. Default: 1.2

  def initialize(options={})

    if options[:keymap]
      @width = options.delete(:width) || calculate_width(options[:keymap])
      @height = options.delete(:height) || calculate_height(options[:keymap])
    else
      @width = options.delete(:width) or raise ArgumentError, 'must provide :width or :keymap'
      @height = options.delete(:height) or raise ArgumentError, 'must provide :height or :keymap'
    end

    @plate_thickness = (options.delete(:plate_thickness) || 1.4).to_f
    @key_unit_size = (options.delete(:key_unit_size) || 19.05).to_f
    @key_hole_size = (options.delete(:key_hole_size) || 14).to_f
    @cutout_height = (options.delete(:cutout_height) || 4).to_f
    @cutout_width = (options.delete(:cutout_width) || 1).to_f
    @include_cutouts = !!options.delete(:include_cutouts)
    @mounting_hole_diameter = (options.delete(:mounting_hole_diameter) || 1.5).to_f
    @case_floor_thickness = (options.delete(:case_floor_thickness) || 1).to_f
    @case_wall_thickness = (options.delete(:case_wall_thickness) || 1.2).to_f

    # total case height: cavity_height + case_floor_thickness
    cavity_height = (options.delete(:cavity_height) || 8).to_f
    @case_height = cavity_height + @case_floor_thickness

    self.truncations = options.delete(:truncations) || []
    self.keymap = options.delete(:keymap) || []
    self.mounting_holes = options.delete(:mounting_holes) || []
  end

  def width_in_mm
    @width_in_mm ||= @width * @key_unit_size
  end

  def height_in_mm
    @height_in_mm ||= @height * @key_unit_size
  end

  def plate
    @plate ||= Plate.new(self)
  end

  def case
    @case ||= Case.new(self)
  end

  # `keymap=` argument expected to array like:
  #
  # [
  #   # Row 0
  #   [ [ 0, 0 ], 1 ], # esc
  #   [ [ 1, 0 ], 1 ], # 1
  #   # Row 1
  #   [ [ 0, 1 ], 1.5 ], # tab
  #   [ [ 1.5, 1 ], 1 ], # q
  # ]
  #
  # [ [ <offset in key_units>, <row in key_units> ], <size in key_units> ]
  def keymap=(keyboard_map)
    @keymap = keyboard_map
  end

  # `truncations=` argument expected to array like:
  #
  # [
  #   # Row 0
  #   [ [ 1, 0 ], :right ], # 1
  #   # Row 1
  #   [ [ 1.5, 1 ], :left ], # q
  # ]
  #
  # [ [ <offset in key_units>, <row in key_units> ], <direction> ]
  def truncations=(truncations_map)
    @truncations = truncations_map.sort_by{|tr|tr[0][1]}
  end

  # `mounting_holes=` argument expected to array like:
  #
  # [
  #   # Row 0
  #   [ 1, 0 ], # between 1, 2 and q
  #   # Row 1
  #   [ 2.5, 1 ], # between q, w and a
  # ]
  #
  # [ <offset in key_units>, <row in key_units> ]
  def mounting_holes=(mounting_holes_map)
    @mounting_holes = mounting_holes_map
  end

  # Calculate the plate/case width in units, based on keymap
  def calculate_width(keymap)
    row_widths=[]
    keymap.each do |coords, size|
      row = coords.last
      row_widths[row] ||= 0
      row_widths[row] += size
    end
    puts "// width: #{row_widths.max}"
    row_widths.max
  end

  # Calculate the plate/case height in units, based on keymap
  def calculate_height(keymap)
    puts "// height: #{keymap.map{|coords, _size|coords.last}.max+1}"
    keymap.map{|coords, _size|coords.last}.max+1
  end

  # common methods for classes descended from ParametricKeyboard
  module Common
    # expect argument to be an instance of ParametricKeyboard
    def initialize(keyboard)
      @keyboard = keyboard
    end

    # width in key units
    def width
      @keyboard.width
    end

    # height in key units
    def height
      @keyboard.height
    end

    # height in mm (height in key units * key_unit_size)
    def height_in_mm
      @keyboard.height_in_mm
    end

    # width in mm (width in key units * key_unit_size)
    def width_in_mm
      @keyboard.width_in_mm
    end

    # keyboard plate thickness in mm
    def thickness
      @keyboard.plate_thickness
    end

    def key_unit_size
      @keyboard.key_unit_size
    end

    def key_hole_size
      @keyboard.key_hole_size
    end

    def case_wall_thickness
      @keyboard.case_wall_thickness
    end

    def case_floor_thickness
      @keyboard.case_floor_thickness
    end

    def case_height
      @keyboard.case_height
    end

    def keymap
      @keyboard.keymap
    end

    def include_cutouts?
      !!@keyboard.include_cutouts
    end

    def cutout_width
      @keyboard.cutout_width
    end

    def cutout_height
      @keyboard.cutout_height
    end

    def truncations
      @keyboard.truncations || []
    end

    def truncations?
      !truncations.empty?
    end

    def mounting_holes
      @keyboard.mounting_holes || []
    end

    def mounting_hole_diameter
      @keyboard.mounting_hole_diameter
    end
  end

  class Plate
    include RubyScad
    include Common

    FF = 0.1 # for better quick-rendering

    # output plate in openscad format
    def to_scad
      union do
        difference do
          bare_plate
          hole_matrix(keymap, 0, height_in_mm - key_unit_size)
          mounting_hole_matrix(mounting_holes, 0, height_in_mm - key_unit_size)
          apply_truncations
        end
      end
    end

    def apply_truncations(options={})
      options = { thickness: thickness }.merge(options)
      if truncations?
        lkey = key_unit_size
        startx = 0
        starty = height_in_mm - lkey
        truncations.each do |truncation|
          toffset = truncation[0][0]
          trow = truncation[0][1]
          tdirection = truncation[1]

          case tdirection
          when :right
            translate(v: [(startx+lkey*toffset), starty-lkey*trow, -FF]) do
              cube(size: [width_in_mm-(startx*toffset),lkey,options[:thickness]+(FF*2)])
            end
          when :left
            translate(v: [0, starty-lkey*trow, -FF]) do
              cube(size: [(startx+lkey*toffset),lkey,options[:thickness]+(FF*2)])
            end
          else
            warn "Unknown truncate direction: #{tdirection}"
          end
        end
      end
    end

    def bare_plate(options={})
      options = { width: width_in_mm, height: height_in_mm, thickness: thickness }.merge(options)
      cube(size: [options[:width], options[:height], options[:thickness]])
    end

    def save_scad(file_path)
      File.new(file_path,'w').close
      @@output_file = file_path
      to_scad
      @@output_file = nil
    end

    def hole_matrix(holes, startx, starty)
      lkey = key_unit_size
      holes.each do |key|
        translate(v: [startx+lkey*key[0][0], starty-lkey*key[0][1], 0]) do
          translate(v: [(lkey*key[1]-key_hole_size)/2,(lkey - key_hole_size)/2, 0]) do
            switchhole
            if key[2..-1].include?(:stabilizers)
              stabilizer_holes
            end
          end
        end
      end
    end

    def switchhole
      union do
        translate(v: [0,0,-FF]) do
          cube(size: [key_hole_size,key_hole_size,thickness+(FF*2)])
          if thickness > 1.4
            translate(v: [-1,-1,1.4]) do # 1.4 is clip thickness for Cherry MX
              # Larger cutout for parts above clip
              cube(size: [key_hole_size+2,key_hole_size+2,thickness+(FF*2)])
            end
          end
        end

        if include_cutouts?
          # Top clip cutout
          translate(v: [-cutout_width,1,0]) do
            cube(size: [key_hole_size+2*cutout_width,cutout_height,thickness])
          end

          # Bottom clip cutout
          translate(v: [-cutout_width,key_hole_size-cutout_width-cutout_height,-FF]) do
            cube(size: [key_hole_size+2*cutout_width,cutout_height,thickness+(FF*2)])
          end
        end
      end
    end

    # Costar stabilizer
    def stabilizer_holes
      slot_spacing = 20.5 # 20.6 (20.5 measured)
      slot_width = 3.7 # 3.3 (3.5 measured)
      slot_height = 14 # 14 (14 measured)
      y_offset = 0.15 # 0.75 is too far down, rubs
      total_width = slot_spacing+(slot_width*2)

      translate(v: [-(total_width/4),-y_offset,-FF]) do
        difference do
          cube(size: [total_width, slot_height, thickness+(FF*2)])
          translate(v: [slot_width, 0, 0]) do
            cube(size: [slot_spacing, slot_height, thickness+(FF*2)])
          end
        end
      end

      if thickness > 1.4 # 1.4 is clip thickness for Cherry MX
        # larger cutout higher up to allow room for stabilizers
        translate(v: [-(total_width/4)-1.5,-y_offset-1,1.4]) do
          difference do
            cube(size: [total_width+3, slot_height+2, thickness+(FF*2)])
            translate(v: [slot_width+3, 0, 0]) do
              cube(size: [slot_spacing-3, slot_height+2, thickness+(FF*2)])
            end
          end
        end
      end
    end

    def mounting_hole_matrix(holes, startx, starty)
      lkey = key_unit_size
      holes.each do |key|
        translate(v: [startx+lkey*key[0], (starty-lkey*key[1])+lkey, -FF]) do
          # translate(v: [(lkey*key[1]-key_hole_size)/2,(lkey - key_hole_size)/2, 0]) do
            mounting_hole
          # end
        end
      end
    end

    def mounting_hole
      cylinder(h: thickness+(FF*2), d: mounting_hole_diameter, fn: 8);
    end
  end

  class Case
    include RubyScad
    include Common

    FF = 0.1 # for better quick-rendering

    # output case in openscad format
    def to_scad
      union do
        difference do
          union do
            difference do
              @keyboard.plate.bare_plate(thickness: case_height)
              translate(
                x: case_wall_thickness,
                y: case_wall_thickness,
                z: case_floor_thickness
              ) do
                @keyboard.plate.bare_plate(
                  width: width_in_mm-(case_wall_thickness*2),
                  height: height_in_mm-(case_wall_thickness*2),
                  thickness: case_height-case_floor_thickness+FF
                )
              end
            end
            mounting_standoff_matrix(mounting_holes, 0, height_in_mm - key_unit_size)
          end
          @keyboard.plate.apply_truncations(thickness: case_height)
        end

        lkey = key_unit_size
        startx = 0
        starty = height_in_mm - lkey
        if truncations?
          right_truncations = truncations.select{|tr| tr[1] == :right}
          right_truncations.each_with_index do |truncation, index|
            trow = truncation[0][1]
            current_end_offset = truncation[0][0]

            previous_truncation = right_truncations.detect{|tr|tr[0][1] == trow - 1}
            next_truncation = right_truncations.detect{|tr|tr[0][1] == trow + 1}

            previous_end_offset = previous_truncation ? previous_truncation[0][0] : width
            next_end_offset = next_truncation ? next_truncation[0][0] : width

            first = index == 0
            last = right_truncations.length == index+1

            if !first && previous_end_offset > current_end_offset
              wall_length = previous_end_offset - current_end_offset
              translate(v: [current_end_offset*lkey-case_wall_thickness,starty-(lkey*(trow-1)), -FF]) do
                cube(size: [(wall_length*lkey)+case_wall_thickness, case_wall_thickness, case_height+(FF*2)])
              end
            end

            if !last && next_end_offset > current_end_offset
              wall_length = next_end_offset - current_end_offset
              translate(v: [current_end_offset*lkey-case_wall_thickness,(starty-(lkey*(trow)))-case_wall_thickness, -FF]) do
                cube(size: [(wall_length*lkey)+case_wall_thickness, case_wall_thickness, case_height+(FF*2)])
              end
            end
          end

          left_truncations = truncations.select{|tr| tr[1] == :left}
          left_truncations.each_with_index do |truncation, index|
            trow = truncation[0][1]
            current_end_offset = truncation[0][0]

            previous_truncation = left_truncations.detect{|tr|tr[0][1] == trow - 1}
            next_truncation = left_truncations.detect{|tr|tr[0][1] == trow + 1}

            previous_end_offset = previous_truncation ? previous_truncation[0][0] : width
            next_end_offset = next_truncation ? next_truncation[0][0] : width

            first = index == 0
            last = left_truncations.length == index+1

            if !first && previous_end_offset > current_end_offset
              wall_length = previous_end_offset - current_end_offset
              # puts "previous_truncation: #{previous_truncation.inspect}"
              # puts "next_truncation: #{next_truncation.inspect}"
              # puts "trow: #{trow}, current_end_offset: #{current_end_offset}, previous_end_offset: #{previous_end_offset}, wall_length: #{wall_length}"
              # puts({ v: [current_end_offset*lkey,starty-lkey*trow, 0] }).inspect
              translate(v: [current_end_offset*lkey,(starty-(lkey*(trow-1)))-case_wall_thickness, -FF]) do
                cube(size: [(wall_length*lkey)+case_wall_thickness, case_wall_thickness, case_height+(FF*2)])
              end
            end

            if !last && next_end_offset > current_end_offset
              wall_length = next_end_offset - current_end_offset
              # puts "previous_truncation: #{previous_truncation.inspect}"
              # puts "next_truncation: #{next_truncation.inspect}"
              # puts "trow: #{trow}, current_end_offset: #{current_end_offset}, next_end_offset: #{next_end_offset}, wall_length: #{wall_length}"
              # puts({ v: [current_end_offset*lkey,starty-lkey*trow, 0] }).inspect
              translate(v: [current_end_offset*lkey,starty-(lkey*(trow)), -FF]) do
                cube(size: [(wall_length*lkey)+case_wall_thickness, case_wall_thickness, case_height+(FF*2)])
              end
            end
          end

          truncations.each do |truncation|
            toffset = truncation[0][0]
            trow = truncation[0][1]
            tdirection = truncation[1]

            # TODO this may be broken
            # right truncations should put the wall on the left
            # left truncations should put the wall on the right
            case tdirection
            when :right
              translate(v: [(startx+lkey*toffset)-case_wall_thickness, starty-lkey*trow, -FF]) do
                cube(size: [case_wall_thickness,lkey,case_height+(FF*2)])
              end
            when :left
              translate(v: [(startx+lkey*toffset), starty-lkey*trow, -FF]) do
                cube(size: [case_wall_thickness,lkey,case_height+(FF*2)])
              end
            else
              warn "Unknown truncate direction: #{tdirection}"
            end
          end
        end
      end
    end

    def mounting_standoff_matrix(holes, startx, starty)
      lkey = key_unit_size
      holes.each do |key|
        translate(v: [startx+lkey*key[0], (starty-lkey*key[1])+lkey, 0]) do
          # translate(v: [(lkey*key[1]-key_hole_size)/2,(lkey - key_hole_size)/2, 0]) do
            mounting_standoff(key[2..-1])
          # end
        end
      end
    end

    def mounting_standoff(options=[])
      if options.include?(:beefy)
        # Beefy supports, flared at the bottom.
        difference do
          cylinder(h: case_height, d1: mounting_hole_diameter+5.5, d2: mounting_hole_diameter+2.3, fn: 8)
          cylinder(h: case_height, d: mounting_hole_diameter, fn: 8)
        end
      else
        # "Normal" supports
        difference do
          cylinder(h: case_height, d: mounting_hole_diameter+2.3, fn: 8)
          cylinder(h: case_height, d: mounting_hole_diameter, fn: 8)
        end
      end
    end

    def save_scad(file_path)
      File.new(file_path, 'w').close
      @@output_file = file_path
      to_scad
      @@output_file = nil
    end
  end


  # accept json string as from a gist saved from keyboard-layout-editor.com.
  # Returns nested-array keymap:
  # [
  #   [[0,0],1], # [[column/x, row/y], size]
  #   ...
  # ]
  #
  # options can be:
  #  :stabilize_at - automatically add stabilizer cutouts to keys this thise or larger.  Default is 2, set to nil to disable.
  #
  # NOTE: Only supports key width and x/y coordinates. Does not support rotation,
  # keys taller that 1x, or anything else.
  def self.keymap_from_json(json, options = {})
    require 'json'
    options = {stabilize_at: 2}.merge(options)


    keymap = [] # output in format above

    current_y = 0 # key units
    JSON.parse(json).select{|e| e.is_a?(Array)}.each do |row|

      next_values = {} # store "next key" attributes
      current_x = 0 # key units
      row.each do |key|

        if key.is_a?(Hash)
          # not a key, but changes in size, x, y, etc.
          current_x = current_x += key['x'] if key['x']
          current_y = current_y += key['y'] if key['y']

          if key['w']
            next_values['w'] = key['w']
          end
        else
          current_key_size = next_values.delete('w') || 1
          keymap << [[current_x, current_y], current_key_size]

          if options[:stabilize_at] && current_key_size >= options[:stabilize_at]
            keymap.last << :stabilizers
          end

          current_x += current_key_size
        end
      end
      current_y += 1
    end
    keymap
  end
end
