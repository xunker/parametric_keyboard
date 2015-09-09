require 'rubyscad'

class ParametricKeyboard
  attr_reader :keymap, :width, :height, :plate_thickness,
    :key_unit_size, :key_hole_size,
    :cutout_width, :cutout_height, :include_cutouts,
    :truncations,
    :cavity_height, :case_floor_thickness, :case_wall_thickness, :case_height

  # `options` hash keys.
  #
  # Required:
  # width   Width of board in units of `key_unit_size`. Can be float.
  # height  Height of the board in units of `key_unit_size`. Can be float.
  # keymap  Map of the keys. Can be set later with `#keymap=`
  #
  # Optional:
  # plate_thickness Thickness of plate in mm. Default: 1.4
  # key_unit_size   Square length of space for a single key unit in mm. Default: 19.05
  # key_hole_size   Square length of cutout for switch in mm. Default: 14
  # cutout_height   Height of switch clasp cutouts in mm. Default: 3
  # cutout_width    Width of switch clasp cutouts in mm. Default 1
  # include_cutouts Include the clasp cutouts? Default: true
  # mounting_hole_radius  Radius in mm of mounting holes.  Default: 1.5
  # truncations     Truncate rows to create partial, non-square plates. Can be set later.
  # cavity_height   Interior height of empty space in lower case. Default 8
  # case_floor_thickness  Thickness of lower case floor. Default: 1
  # case_wall_thickness   Thickness of lower case walls. Default 1.2;

  def initialize(options={})
    @width = options.delete(:width) or raise ArgumentError, 'must provide :width'
    @height = options.delete(:height) or raise ArgumentError, 'must provide :height'

    @plate_thickness = (options.delete(:plate_thickness) || 1.4).to_f
    @key_unit_size = (options.delete(:key_unit_size) || 19.05).to_f
    @key_hole_size = (options.delete(:key_hole_size) || 14).to_f
    @cutout_height = (options.delete(:cutout_height) || 4).to_f
    @cutout_width = (options.delete(:cutout_width) || 1).to_f
    @include_cutouts = !!options.delete(:include_cutouts)
    @mounting_hole_radius = (options.delete(:mounting_hole_radius) || 1.5).to_f
    @case_floor_thickness = (options.delete(:case_floor_thickness) || 1).to_f
    @case_wall_thickness = (options.delete(:case_wall_thickness) || 1.2).to_f

    # total case height: cavity_height + case_floor_thickness
    cavity_height = (options.delete(:cavity_height) || 8).to_f
    @case_height = cavity_height + @case_floor_thickness

    self.truncations = options.delete(:truncations)
    self.keymap = options.delete(:keymap)
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
  end

  class Plate
    include RubyScad
    include Common

    # output plate in openscad format
    def to_scad
      union do
        difference do
          bare_plate
          hole_matrix(keymap, 0, height_in_mm - key_unit_size);
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
            translate(v: [startx+lkey*toffset, starty-lkey*trow, 0]) do
              cube(size: [width_in_mm-(startx*toffset),lkey,options[:thickness]]);
            end
          when :left
            translate(v: [0, starty-lkey*trow, 0]) do
              cube(size: [(startx+lkey*toffset),lkey,options[:thickness]]);
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
          end
        end
      end
    end

    def switchhole
      union do
        cube(size: [key_hole_size,key_hole_size,thickness])

        if include_cutouts?
          # Top clip cutout
          translate(v: [-cutout_width,1,0]) do
            cube(size: [key_hole_size+2*cutout_width,cutout_height,thickness])
          end

          # Bottom clip cutout
          translate(v: [-cutout_width,key_hole_size-cutout_width-cutout_height,0]) do
            cube(size: [key_hole_size+2*cutout_width,cutout_height,thickness])
          end
        end
      end
    end
  end

  class Case
    include RubyScad
    include Common

    # output case in openscad format
    def to_scad
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
              thickness: case_height-case_floor_thickness
            )
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
              translate(v: [current_end_offset*lkey,starty-(lkey*(trow-1)), 0]) do
                cube(size: [(wall_length*lkey)+case_wall_thickness, case_wall_thickness, case_height])
              end
            end

            if !last && next_end_offset > current_end_offset
              wall_length = next_end_offset - current_end_offset
              translate(v: [current_end_offset*lkey,(starty-(lkey*(trow)))-case_wall_thickness, 0]) do
                cube(size: [(wall_length*lkey)+case_wall_thickness, case_wall_thickness, case_height])
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
              translate(v: [current_end_offset*lkey,(starty-(lkey*(trow-1)))-case_wall_thickness, 0]) do
                cube(size: [(wall_length*lkey)+case_wall_thickness, case_wall_thickness, case_height])
              end
            end

            if !last && next_end_offset > current_end_offset
              wall_length = next_end_offset - current_end_offset
              # puts "previous_truncation: #{previous_truncation.inspect}"
              # puts "next_truncation: #{next_truncation.inspect}"
              # puts "trow: #{trow}, current_end_offset: #{current_end_offset}, next_end_offset: #{next_end_offset}, wall_length: #{wall_length}"
              # puts({ v: [current_end_offset*lkey,starty-lkey*trow, 0] }).inspect
              translate(v: [current_end_offset*lkey,starty-(lkey*(trow)), 0]) do
                cube(size: [(wall_length*lkey)+case_wall_thickness, case_wall_thickness, case_height])
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
              translate(v: [(startx+lkey*toffset), starty-lkey*trow, 0]) do
                cube(size: [case_wall_thickness,lkey,case_height])
              end
            when :left
              translate(v: [(startx+lkey*toffset), starty-lkey*trow, 0]) do
                cube(size: [case_wall_thickness,lkey,case_height])
              end
            else
              warn "Unknown truncate direction: #{tdirection}"
            end
          end
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
end
