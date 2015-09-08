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
  # key_unit_length Square length of space for a single key unit in mm. Default: 19.05
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
    @cavity_height = (options.delete(:cavity_height) || 8).to_f
    @case_floor_thickness = (options.delete(:case_floor_thickness) || 1).to_f
    @case_wall_thickness = (options.delete(:case_wall_thickness) || 1.2).to_f

    # total case height: cavity_height + case_floor_thickness
    @case_height = @cavity_height + @case_floor_thickness

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
  #   [ [ 1, 0 ], 1, :right ], # 1
  #   # Row 1
  #   [ [ 1.5, 1 ], 1, :left ], # q
  # ]
  #
  # [ [ <offset in key_units>, <row in key_units> ], <size in key_units>, <direction> ]
  def truncations=(truncations_map)
    @truncations = truncations_map
  end

  class Plate
    include RubyScad
    # expect argument to be an instance of ParametricKeyboard
    def initialize(keyboard)
      @keyboard = keyboard
    end

    # output plate in openscad format
    def to_scad
      difference do
        bare_plate
        hole_matrix(@keyboard.keymap, 0, height_in_mm - key_unit_size);
        apply_truncations
      end
    end

    def apply_truncations(options={})
      options = { thickness: thickness }.merge(options)
      if truncations = @keyboard.truncations
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
      File.new(file_path, 'w').close
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
      cutoutwidth = @keyboard.cutout_width
      cutoutheight = @keyboard.cutout_height
      union do
        cube(size: [key_hole_size,key_hole_size,thickness])

        if @keyboard.include_cutouts
          # Top clip cutout
          translate(v: [-cutoutwidth,1,0]) do
            cube(size: [key_hole_size+2*cutoutwidth,cutoutheight,thickness])
          end

          # Bottom clip cutout
          translate(v: [-cutoutwidth,key_hole_size-cutoutwidth-cutoutheight,0]) do
            cube(size: [key_hole_size+2*cutoutwidth,cutoutheight,thickness])
          end
        end
      end
    end

    def height_in_mm
      @keyboard.height_in_mm
    end

    def width_in_mm
      @keyboard.width_in_mm
    end

    def thickness
      @keyboard.plate_thickness
    end

    def key_unit_size
      @keyboard.key_unit_size
    end

    def key_hole_size
      @keyboard.key_hole_size
    end
  end

  class Case
    include RubyScad
    # expect argument to be an instance of ParametricKeyboard
    def initialize(keyboard)
      @keyboard = keyboard
    end

    # output case in openscad format
    def to_scad
      difference do
        @keyboard.plate.bare_plate(thickness: @keyboard.case_height)
        translate(
          x: @keyboard.case_wall_thickness,
          y: @keyboard.case_wall_thickness,
          z: @keyboard.case_floor_thickness
        ) do
          @keyboard.plate.bare_plate(
            width: @keyboard.width_in_mm-(@keyboard.case_wall_thickness*2),
            height: @keyboard.height_in_mm-(@keyboard.case_wall_thickness*2),
            thickness: @keyboard.case_height-@keyboard.case_floor_thickness
          )
        end
        @keyboard.plate.apply_truncations(thickness: @keyboard.case_height)
      end

      lkey = @keyboard.key_unit_size
      startx = 0
      starty = @keyboard.height_in_mm - lkey
      if truncations = @keyboard.truncations
        truncations.each do |truncation|
          toffset = truncation[0][0]
          trow = truncation[0][1]
          tdirection = truncation[1]

          if trunc_above = truncations.detect{|tr| tr[1] == tdirection && tr[0][1] == trow + 1}
            if trunc_above[0][0] > toffset
              wall_length = (trunc_above[0][0] - toffset) * lkey

              translate(v: [startx+lkey*toffset, starty-lkey*trow, 0]) do
                cube(size: [wall_length+@keyboard.case_wall_thickness, @keyboard.case_wall_thickness, @keyboard.case_height])
              end
            end

            if trunc_above[0][0] < toffset
              wall_length = (toffset - trunc_above[0][0]) * lkey

              translate(v: [(startx+lkey*toffset)-wall_length, starty-lkey*trow, 0]) do
                cube(size: [wall_length+@keyboard.case_wall_thickness, @keyboard.case_wall_thickness, @keyboard.case_height])
              end
            end
          end

          case tdirection
          when :right
            translate(v: [startx+lkey*toffset, starty-lkey*trow, 0]) do
              cube(size: [@keyboard.case_wall_thickness,lkey,@keyboard.case_height])
            end
          when :left
            translate(v: [(startx+lkey*toffset), starty-lkey*trow, 0]) do
              cube(size: [@keyboard.case_wall_thickness,lkey,@keyboard.case_height])
            end
          else
            warn "Unknown truncate direction: #{tdirection}"
          end
        end
      end

      # def bare_plate(options={})
      # options = { width: width_in_mm, height: height_in_mm, thickness: thickness }.merge(options)
      # cube(size: [options[:width], options[:height], options[:thickness]])
    # end
    #   :keymap, :width, :height, :plate_thickness,
    # :key_unit_size, :key_hole_size,
    # :cutout_width, :cutout_height, :include_cutouts,
    # :truncations,
    # :cavity_height, :case_floor_thickness, :case_wall_thickness, :case_height
    # difference do

    end

    def save_scad(file_path)
      File.new(file_path, 'w').close
      @@output_file = file_path
      to_scad
      @@output_file = nil
    end

    def height_in_mm
      @keyboard.height_in_mm
    end

    def width_in_mm
      @keyboard.width_in_mm
    end

    def thickness
      @keyboard.plate_thickness
    end

    def key_unit_size
      @keyboard.key_unit_size
    end

    def key_hole_size
      @keyboard.key_hole_size
    end
  end
end

# //Thickness of entire plate
# plateThickness=1.4;
# //Unit square length, from Cherry MX data sheet
# lkey=19.05;
# //Hole size, from Cherry MX data sheet
# holesize=14;
# //length, in units, of board
# width=14.5;
# //Height, in units, of board
# height=5;
# //Radius of mounting holes
# mountingholeradius=1.5;
# //height of switch clasp cutouts
# cutoutheight = 3;
# //width of switch clasp cutouts
# cutoutwidth = 1;

# // lower case generation
# // cavity_height is the space in the lower case. Needs to be at last as tall
# // as much as the key switches will extend below the plate or else they won't
# // fit together.
# cavity_height = 8;

# // case_floor_thickness: recommended to be at least 1.0mm. Also recommended to
# // be an even multiple of your layer height. E.g., if layer height is 0.3mm,
# // use 1.2 or 1.5. Don't use 1.0 because it can't be evenly divided by 0.3.
# case_floor_thickness = 0.9;
# // total case height: cavity_height + case_floor_thickness
# case_height = cavity_height + case_floor_thickness;
# // case_wall_thickness: For rigidity, recommend to be at least 3x your nozzle
# // size. Also recommended to be an even multiple of your nozzle size.
# case_wall_thickness = 1.2;
# // inner and outer radius of mounting standoff on case
# mount_receiver_outer_radius = mountingholeradius+0.5;
# mount_receiver_inner_radius = mountingholeradius-0.5;


# //calculated vars

# holediff=lkey-holesize;
# w=width*lkey;
# h=height*lkey;

# // [[column, row], offset (key width)]
# //my custom keyboard layout layer
# // http://www.keyboard-layout-editor.com/##@@=Esc&=!%0A1&=%2F@%0A2&=%23%0A3&=$%0A4&=%25%0A5&=%5E%0A6&=%2F&%0A7&=*%0A8&=(%0A9&=)%0A0&=%2F_%0A-&=+%0A%2F=&_w:1.5%3B&=Backspace%3B&@_w:1.5%3B&=Tab&=Q&=W&=E&=R&=T&=Y&=U&=I&=O&=P&=%7B%0A%5B&=%7D%0A%5D&=%7C%0A%5C%3B&@_w:1.75%3B&=Ctrl%0ACaps&=A&=S&=D&=F&=G&=H&=J&=K&=L&=%2F:%0A%2F%3B&=%22%0A'&_w:1.75%3B&=Enter%3B&@_w:2.25%3B&=Shift&=Z&=X&=C&=V&=B&=N&=M&=%3C%0A,&=%3E%0A.&_w:1.25%3B&=%3F%0A%2F%2F&=%E2%86%91&=Shift%0A%E7%84%A1%E5%A4%89%E6%8F%9B%3B&@=Fn&=~%0A%0A%0A%0A%0A%0A%60&=Alt&_w:1.25%3B&=Cmd%0A%E8%8B%B1%E6%95%B0&_w:3%3B&=&_w:3%3B&=&_w:1.25%3B&=Cmd%0A%E3%81%8B%E3%81%AA%0A%0A%0A%0A%0A%E3%82%AB%E3%83%8A&=%E2%86%90&=%E2%86%93&=%E2%86%92
# myKeyboard = [
# //start ROW 0
# [[0,0],1], // esc
# [[1,0],1], // 1
# [[2,0],1], // 2
# [[3,0],1], // 3
# [[4,0],1], // 4
# [[5,0],1], // 5
# [[6,0],1], // 6
# [[7,0],1], // 7
# [[8,0],1], // 8
# [[9,0],1], // 9
# [[10,0],1], // 0
# [[11,0],1], // -
# [[12,0],1], // =
# [[13,0],1.5], // bksp
# //start ROW 1
# [[  0,1],1.5], // tab
# [[1.5,1],1], // q
# [[2.5,1],1], // w
# [[3.5,1],1], // e
# [[4.5,1],1], // r
# [[5.5,1],1], // t
# [[6.5,1],1], // y
# [[7.5,1],1], // u
# [[8.5,1],1], // i
# [[9.5,1],1], // o
# [[10.5,1],1], // p
# [[11.5,1],1], // [
# [[12.5,1],1], // ]
# [[13.5,1],1], // \
# //start ROW 2
# [[   0,2],1.75], // ctrl
# [[1.75,2],1], // a
# [[2.75,2],1], // s
# [[3.75,2],1], // d
# [[4.75,2],1], // f
# [[5.75,2],1], // g
# [[6.75,2],1], // h
# [[7.75,2],1], // j
# [[8.75,2],1], // k
# [[9.75,2],1], // l
# [[10.75,2],1], // ;
# [[11.75,2],1], // '
# [[12.75,2],1.75], // enter
# //start ROW 3
# [[   0,3],2.25], // lshift
# [[2.25,3],1], // z
# [[3.25,3],1], // x
# [[4.25,3],1], // c
# [[5.25,3],1], // v
# [[6.25,3],1], // b
# [[7.25,3],1], // n
# [[8.25,3],1], // m
# [[9.25,3],1], // ,
# [[10.25,3],1], // .
# [[11.25,3],1.25], // /
# [[12.50,3],1], // up arrow
# [[13.50,3],1], // rshift
# //start ROW 4
# [[0,4],1], // fn
# [[1,4],1], // `
# [[2,4],1], // alt
# [[3,4],1.25], // lcmd
# [[4.25,4],3], // space 1
# [[7.25,4],3], // space 2
# [[10.25,4],1.25], // rcmd
# [[11.5,4],1], // left arrow
# [[12.5 ,4],1], // down arrow
# [[13.5,4],1], // right arrow
# ];

# // [[column, row], offset (key width)]
# myHalfKeyboardleft = [
# //start ROW 0
# [[0,0],1], // esc
# [[1,0],1], // 1
# [[2,0],1], // 2
# [[3,0],1], // 3
# [[4,0],1], // 4
# [[5,0],1], // 5
# [[6,0],1], // 6
# // [[7,0],1], // 7
# // [[8,0],1], // 8
# // [[9,0],1], // 9
# // [[10,0],1], // 0
# // [[11,0],1], // -
# // [[12,0],1], // =
# // [[13,0],1.5], // bksp
# //start ROW 1
# [[  0,1],1.5], // tab
# [[1.5,1],1], // q
# [[2.5,1],1], // w
# [[3.5,1],1], // e
# [[4.5,1],1], // r
# [[5.5,1],1], // t
# // [[6.5,1],1], // y
# // [[7.5,1],1], // u
# // [[8.5,1],1], // i
# // [[9.5,1],1], // o
# // [[10.5,1],1], // p
# // [[11.5,1],1], // [
# // [[12.5,1],1], // ]
# // [[13.5,1],1], // \
# //start ROW 2
# [[   0,2],1.75], // ctrl
# [[1.75,2],1], // a
# [[2.75,2],1], // s
# [[3.75,2],1], // d
# [[4.75,2],1], // f
# [[5.75,2],1], // g
# // [[6.75,2],1], // h
# // [[7.75,2],1], // j
# // [[8.75,2],1], // k
# // [[9.75,2],1], // l
# // [[10.75,2],1], // ;
# // [[11.75,2],1], // '
# // [[12.75,2],1.75], // enter
# //start ROW 3
# [[   0,3],2.25], // lshift
# [[2.25,3],1], // z
# [[3.25,3],1], // x
# [[4.25,3],1], // c
# [[5.25,3],1], // v
# [[6.25,3],1], // b
# // [[7.25,3],1], // n
# // [[8.25,3],1], // m
# // [[9.25,3],1], // ,
# // [[10.25,3],1], // .
# // [[11.25,3],1.25], // /
# // [[12.50,3],1], // up arrow
# // [[13.50,3],1], // rshift
# //start ROW 4
# [[0,4],1], // fn
# [[1,4],1], // `
# [[2,4],1], // alt
# [[3,4],1.25], // lcmd
# [[4.25,4],3], // space 1
# // [[7.25,4],3], // space 2
# // [[10.25,4],1.25], // rcmd
# // [[11.5,4],1], // left arrow
# // [[12.5 ,4],1], // down arrow
# // [[13.5,4],1], // right arrow
# ];

# // [[column, row], offset (key width)]
# myHalfKeyboardright = [
# //start ROW 0
# // [[0,0],1], // esc
# // [[1,0],1], // 1
# // [[2,0],1], // 2
# // [[3,0],1], // 3
# // [[4,0],1], // 4
# // [[5,0],1], // 5
# // [[6,0],1], // 6
# [[7,0],1], // 7
# [[8,0],1], // 8
# [[9,0],1], // 9
# [[10,0],1], // 0
# [[11,0],1], // -
# [[12,0],1], // =
# [[13,0],1.5], // bksp
# //start ROW 1
# // [[  0,1],1.5], // tab
# // [[1.5,1],1], // q
# // [[2.5,1],1], // w
# // [[3.5,1],1], // e
# // [[4.5,1],1], // r
# // [[5.5,1],1], // t
# [[6.5,1],1], // y
# [[7.5,1],1], // u
# [[8.5,1],1], // i
# [[9.5,1],1], // o
# [[10.5,1],1], // p
# [[11.5,1],1], // [
# [[12.5,1],1], // ]
# [[13.5,1],1], // \
# //start ROW 2
# // [[   0,2],1.75], // ctrl
# // [[1.75,2],1], // a
# // [[2.75,2],1], // s
# // [[3.75,2],1], // d
# // [[4.75,2],1], // f
# // [[5.75,2],1], // g
# [[6.75,2],1], // h
# [[7.75,2],1], // j
# [[8.75,2],1], // k
# [[9.75,2],1], // l
# [[10.75,2],1], // ;
# [[11.75,2],1], // '
# [[12.75,2],1.75], // enter
# //start ROW 3
# // [[   0,3],2.25], // lshift
# // [[2.25,3],1], // z
# // [[3.25,3],1], // x
# // [[4.25,3],1], // c
# // [[5.25,3],1], // v
# // [[6.25,3],1], // b
# [[7.25,3],1], // n
# [[8.25,3],1], // m
# [[9.25,3],1], // ,
# [[10.25,3],1], // .
# [[11.25,3],1.25], // /
# [[12.50,3],1], // up arrow
# [[13.50,3],1], // rshift
# //start ROW 4
# // [[0,4],1], // fn
# // [[1,4],1], // `
# // [[2,4],1], // alt
# // [[3,4],1.25], // lcmd
# // [[4.25,4],3], // space 1
# [[7.25,4],3], // space 2
# [[10.25,4],1.25], // rcmd
# [[11.5,4],1], // left arrow
# [[12.5 ,4],1], // down arrow
# [[13.5,4],1], // right arrow
# ];

# //poker keyboard layout layer
# pokerkeyboard = [
# //start ROW 0
# [[0,0],1],
# [[1,0],1],
# [[2,0],1],
# [[3,0],1],
# [[4,0],1],
# [[5,0],1],
# [[6,0],1],
# [[7,0],1],
# [[8,0],1],
# [[9,0],1],
# [[10,0],1],
# [[11,0],1],
# [[12,0],1],
# [[13,0],2],
# //start ROW 1
# [[  0,1],1.5],
# [[1.5,1],1],
# [[2.5,1],1],
# [[3.5,1],1],
# [[4.5,1],1],
# [[5.5,1],1],
# [[6.5,1],1],
# [[7.5,1],1],
# [[8.5,1],1],
# [[9.5,1],1],
# [[10.5,1],1],
# [[11.5,1],1],
# [[12.5,1],1],
# [[13.5,1],1.5],
# //start ROW 2
# [[   0,2],1.75],
# [[1.75,2],1],
# [[2.75,2],1],
# [[3.75,2],1],
# [[4.75,2],1],
# [[5.75,2],1],
# [[6.75,2],1],
# [[7.75,2],1],
# [[8.75,2],1],
# [[9.75,2],1],
# [[10.75,2],1],
# [[11.75,2],1],
# [[12.75,2],2.25],
# //start ROW 3
# [[   0,3],2.25],
# [[2.25,3],1],
# [[3.25,3],1],
# [[4.25,3],1],
# [[5.25,3],1],
# [[6.25,3],1],
# [[7.25,3],1],
# [[8.25,3],1],
# [[9.25,3],1],
# [[10.25,3],1],
# [[11.25,3],1],
# [[12.25,3],2.75],
# //start ROW 4
# [[   0,4],1.25],
# [[1.25,4],1.25],
# [[2.5 ,4],1.25],
# [[3.75,4],6.25],
# [[10  ,4],1.25],
# [[11.25,4],1.25],
# [[12.5 ,4],1.25],
# [[13.75,4],1.25],
# ];

# // small keyboard to test fitting
# testKeyboard = [
# //start ROW 0
# [[0,0.5],1], // key
# [[1,0],1], // key
# [[2,0],1], // key
# [[3,0],1], // key
# [[4,0.25],1], // key
# //start ROW 1
# [[0,1.5],1], // key
# [[1,1],1], // key
# [[2,1],1], // key
# [[3,1],1], // key
# [[4,1.25],1], // key
# //start ROW 2
# [[0,2.5],1], // key
# [[1,2],1], // key
# [[2,2],1], // key
# [[3,2],1], // key
# [[4,2.25],1], // key
# ];

# module plate(w,h){
#   cube([w,h,plateThickness]);
# }

# module switchhole(){
#   union(){
#     cube([holesize,holesize,plateThickness]);

#     // Top clip cutout
#     // translate([-cutoutwidth,1,0])
#     // cube([holesize+2*cutoutwidth,cutoutheight,plateThickness]);

#     // Bottom clip cutout
#     // translate([-cutoutwidth,holesize-cutoutwidth-cutoutheight,0])
#     // cube([holesize+2*cutoutwidth,cutoutheight,plateThickness]);
#   }
# }

# row_maximums = [];

# module holematrix(holes,startx,starty){
#   for (key = holes){
#     translate([startx+lkey*key[0][0], starty-lkey*key[0][1], 0])
#     translate([(lkey*key[1]-holesize)/2,(lkey - holesize)/2, 0])
#     switchhole();
#   }
# }

# module mountingholes(){
#   translate([(1+1/3)*lkey,3.5*lkey,0]) mounting_hole();

#   translate([(13+2/3)*lkey,3.5*lkey,0]) mounting_hole();

#   translate([(6.75)*lkey,2.5*lkey,0]) mounting_hole();

#   translate([(6.75)*lkey,2.5*lkey,0]) mounting_hole();

#   translate([(14.8)*lkey,2*lkey,0]) mounting_hole();

#   translate([(.2)*lkey,2*lkey,0]) mounting_hole();

#   translate([(10)*lkey,.5*lkey,0]) mounting_hole();
# }

# module mounting_hole(){
#   cylinder(h=plateThickness,r=mountingholeradius, $fn=16);
# }

# module mounting_standoff(){
#   difference() {
#     // bottom of standoff is flared for stability
#     cylinder(h=case_height,r1=mount_receiver_outer_radius+1.3, r2=mount_receiver_outer_radius, $fn=16);
#     cylinder(h=case_height,r=mount_receiver_inner_radius, $fn=16);
#   }
# }

# module myplate(){
#   difference(){
#     plate(w,h);
#     holematrix(myKeyboard,0,h-lkey);
#     // mountingholes();
#     //translate([152.5,0,0]) cube([.001,150,150]);
#   }
# }

# module myhalfplate(){
#   difference(){
#     plate(w,h);

#     truncations = [
#       [[7,0],1],
#       [[6.5,1],1],
#       [[6.75,2],1],
#       [[7.25,3],1],
#       [[7.25,4],3]
#     ];
#     truncateplateright(0,h-lkey,plateThickness,truncations);

#     // truncations = [
#     //   [[6,0],1], // 6
#     //   [[5.5,1],1], // t
#     //   [[5.75,2],1], // g
#     //   [[6.25,3],1], // b
#     //   [[4.25,4],3], // space 1
#     // ];
#     // truncateplateleft(0,h-lkey,plateThickness,truncations);

#     holematrix(myHalfKeyboardleft,0,h-lkey);
#     // holematrix(myHalfKeyboardright,0,h-lkey);
#     // mountingholes();
#     //translate([152.5,0,0]) cube([.001,150,150]);
#   }
# }

# module myhalfcase(){
#   // difference() {
#   //   cube([w,h,case_height]);
#   //   translate([case_wall_thickness,case_wall_thickness,case_floor_thickness])
#   //     cube([w-(case_wall_thickness*2),h-(case_wall_thickness*2),case_height]);
#   // }
#   truncations = [
#     [[6,0],1], // 6
#     [[5.5,1],1], // t
#     [[5.75,2],1], // g
#     [[6.25,3],1], // b
#     [[4.25,4],3], // space 1
#   ];
#   difference() {
#     // scale([case_wall_thickness,case_wall_thickness,case_floor_thickness])
#     truncateplateleft(0,h-lkey,case_height,truncations);
#     scale([0.9,0.95,1.0])
#       translate([case_wall_thickness,case_wall_thickness,case_floor_thickness])
#         truncateplateleft(0,h-lkey,case_height,truncations);

#   }
# }

# module truncateplateright(startx, starty, thickness, truncations) {
#   // startx = 0;
#   // starty = h-lkey;
#   for (truncation = truncations){
#     toffset = truncation[0][0];
#     trow = truncation[0][1];
#     twidth = truncation[1];
#     echo(toffset=toffset, trow=trow, twidth=twidth);
#     translate([startx+lkey*toffset, starty-lkey*trow, 0]) {
#       // translate([(lkey*twidth-holesize)/2,(lkey - holesize)/2, 0]) {
#         cube([w,lkey,thickness]);
#       // }
#     }
#   }
# }

# module truncateplateleft(startx, starty, thickness, truncations) {
#   // startx = 0;
#   // starty = h-lkey;
#   for (truncation = truncations){
#     toffset = truncation[0][0];
#     trow = truncation[0][1];
#     twidth = truncation[1];
#     echo(toffset=toffset, trow=trow, twidth=twidth);
#     translate([0, starty-lkey*trow, 0]) {
#       // translate([(lkey*twidth-holesize)/2,(lkey - holesize)/2, 0]) {
#         cube([(startx+lkey*toffset)+(twidth*lkey),lkey,thickness]);
#       // }
#     }
#   }
# }

# module pokerplate(){
#   difference(){
#     plate(w,h);
#     holematrix(pokerkeyboard,0,h-lkey);
#     mountingholes();
#   }
# }

# module testplate(){
#   difference(){
#     plate(w,h);
#     holematrix(testKeyboard,0,h-lkey);
#     // mounting holes
#     translate([lkey/5,(height*lkey)-(lkey/5),0]) mounting_hole();
#     translate([(width*lkey)-(lkey/5),(height*lkey)-(lkey/5),0]) mounting_hole();

#     translate([lkey/5,lkey/5,0]) mounting_hole();
#     translate([(width*lkey)-(lkey/5),lkey/5,0]) mounting_hole();

#     translate([((width/2)*lkey),lkey/5,0]) mounting_hole();

#     translate([(lkey*1),lkey*0.75,0]) mounting_hole();
#     translate([(lkey*1),lkey*1.75,0]) mounting_hole();
#     translate([(lkey*1),lkey*2.75,0]) mounting_hole();

#     translate([(lkey*2),lkey*0.75,0]) mounting_hole();
#     translate([(lkey*2),lkey*1.75,0]) mounting_hole();
#     translate([(lkey*2),lkey*2.75,0]) mounting_hole();

#     translate([(lkey*3),lkey*0.75,0]) mounting_hole();
#     translate([(lkey*3),lkey*1.75,0]) mounting_hole();
#     translate([(lkey*3),lkey*2.75,0]) mounting_hole();

#     translate([(lkey*4),lkey*0.75,0]) mounting_hole();
#     translate([(lkey*4),lkey*1.75,0]) mounting_hole();
#     translate([(lkey*4),lkey*2.75,0]) mounting_hole();

#     // translate([(lkey*3)+(lkey/2),lkey/3,0])
#     // cylinder(h=plateThickness,r=mountingholeradius, $fn=16);
#     // translate([(lkey*4)+(lkey/1.5),lkey/5,0])
#     // cylinder(h=plateThickness,r=mountingholeradius, $fn=16);
#   }
# }

# module testcase(){
#   difference() {
#     cube([w,h,case_height]);
#     translate([case_wall_thickness,case_wall_thickness,case_floor_thickness])
#       cube([w-(case_wall_thickness*2),h-(case_wall_thickness*2),case_height]);
#   }

#   // mounting hole standoffs
#   translate([lkey/5,(height*lkey)-(lkey/5),0]) mounting_standoff();
#   translate([(width*lkey)-(lkey/5),(height*lkey)-(lkey/5),0]) mounting_standoff();

#   translate([lkey/5,lkey/5,0]) mounting_standoff();
#   translate([(width*lkey)-(lkey/5),lkey/5,0]) mounting_standoff();

#   translate([((width/2)*lkey),lkey/5,0]) mounting_standoff();

#   translate([(lkey*1),lkey*0.75,0]) mounting_standoff();
#   translate([(lkey*1),lkey*1.75,0]) mounting_standoff();
#   translate([(lkey*1),lkey*2.75,0]) mounting_standoff();

#   translate([(lkey*2),lkey*0.75,0]) mounting_standoff();
#   translate([(lkey*2),lkey*1.75,0]) mounting_standoff();
#   translate([(lkey*2),lkey*2.75,0]) mounting_standoff();

#   translate([(lkey*3),lkey*0.75,0]) mounting_standoff();
#   translate([(lkey*3),lkey*1.75,0]) mounting_standoff();
#   translate([(lkey*3),lkey*2.75,0]) mounting_standoff();

#   translate([(lkey*4),lkey*0.75,0]) mounting_standoff();
#   translate([(lkey*4),lkey*1.75,0]) mounting_standoff();
#   translate([(lkey*4),lkey*2.75,0]) mounting_standoff();
# }

# // pokerplate();
# // myplate();

# myhalfplate();
# // myhalfcase();

# // test plate setting here
# //length, in units, of board
# // width=5;
# //Height, in units, of board
# // height=3.75;
# // testplate();
# // testcase();