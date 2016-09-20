FF = 0.1;
key_unit_size = 19.05;

thickness = 1.2;

x_unit_width = 1;
y_unit_length = 1.25;

hole_x_offset = 3;
hole_y_offset = 2;
hole_d = 3.5;
  /*[-3, 2],
  [width+3, 2],
  [-3, length-2],
  [width+3, length-2],
].each do |hole_x, hole_y|
  translate(v: [hole_x,hole_y,0]) do
    cylinder(d:3, h: case_floor_thickness+(FF*2),fn: 6)
  end
end*/

screw_tab_outer = hole_d+4;

module screw_tab() {

  difference() {
    union() {
      cylinder(d=screw_tab_outer, h=thickness, $fn=8);
      translate([0,-screw_tab_outer/2, 0])  cube([screw_tab_outer/2, screw_tab_outer, thickness]);
    }
    translate([0,0,-FF]) cylinder(d=hole_d, h=thickness+FF*2, $fn=8);
  }


}

module ramp() {
  difference() {
    cube([x_unit_width*key_unit_size, y_unit_length*key_unit_size, thickness*5]);
    translate([0,-1,1]) rotate([5,0,0]) cube([x_unit_width*key_unit_size, (y_unit_length*key_unit_size)*1.5, thickness*5]);
  }
}

difference(){
  ramp();
  translate([1.1,3,0])scale([0.9,0.9,0.8]) ramp();
}

translate([-hole_x_offset,hole_y_offset+(hole_d/2),0]) {
  screw_tab();
  translate([0,(y_unit_length*key_unit_size)-screw_tab_outer,0]) screw_tab();
}

translate([(x_unit_width*key_unit_size)+hole_x_offset,hole_y_offset+(hole_d/2),0]) {
  rotate([0,0,180]) screw_tab();
  translate([0,(y_unit_length*key_unit_size)-screw_tab_outer,0]) rotate([0,0,180]) screw_tab();
}
