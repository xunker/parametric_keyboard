holes = 3;
hole_d = 3;
spacing = 4.2;
thickness = 2;

ff = 0.1;

module body() {
  difference() {
    cube([hole_d*2, (holes)*(hole_d*1.75), thickness]);
    translate([hole_d, hole_d, -ff]) {
      for(a=[0:holes-1]) {
        translate([0, a*spacing,0]) cylinder(d=hole_d, h=thickness+(ff*2), $fn=8);
      }
    }
  }
}

module bolt_holder() {
  difference() {
    union() {
      cylinder(d=6, h=thickness);
      translate([-3,0,0]) cube([6,6,thickness]);
    }
    translate([0,0,-ff]) cylinder(d=3.25, h=thickness+(ff*2), $fn=8);
  }
}

module simple_support() {
  body();
  translate([hole_d,-hole_d-3,0]) bolt_holder();
}

// simple_support();

module simple_slider() {
  difference() {
    cube([hole_d*3, (holes)*(hole_d*3), thickness]);
    hull() {
      translate([hole_d, hole_d, -ff]) {
        for(a=[0:holes-1]) {
          translate([0, a*spacing*2.5,0]) cylinder(d=hole_d, h=thickness+(ff*2), $fn=8);
        }
      }
    }
  }
  translate([hole_d*3, 0, 0]) {
    difference() {
      cube([hole_d*3, (holes)*(hole_d*3), 12]);
      translate([-ff, 0, thickness]) rotate([30,0,0]) cube([hole_d*3+(ff*2), (holes)*(hole_d*2)*2, 10]);
	  //translate([-ff, 20, 12]) rotate([-55,0,0]) cube([hole_d*3+(ff*2), (holes)*(hole_d*2)*2, 10]);
	  //translate([-ff, 5, 11]) rotate([-5,0,0]) cube([hole_d*3+(ff*2), (holes)*(hole_d*2)*2, 10]);	
    }


  }

}

//simple_slider();
translate([40,0,0]) mirror([1,0,0]) simple_slider();

