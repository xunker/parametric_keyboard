holes = 3;
hole_d = 3;
spacing = 19.05 * 0.3;

ff = 0.1;

module body() {
  difference() {
    cube([hole_d*2, (holes)*spacing, 1]);
    translate([hole_d, hole_d, -ff]) {
      for(a=[0:holes-1]) {
        translate([0, a*spacing,0]) cylinder(d=hold_d, h=1+(ff*2), $fn=8);
      }
    }
  }
}

module bolt_holder() {
  difference() {
    union() {
      cylinder(d=6, h=1);
      translate([-3,0,0]) cube([6,3,1]);
    }
    translate([0,0,-ff]) cylinder(d=3, h=1+(ff*2), $fn=8);
  }
}
body();
translate([hole_d,-hole_d,0]) bolt_holder();
