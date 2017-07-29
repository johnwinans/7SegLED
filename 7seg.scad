// ****************************************************************************
//
//    7SegLED - a 3D printable 7-segment LED
//
//    Copyright (C) 2017 John Winans
//
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with this program. If not, see <http://www.gnu.org/licenses/>.
//
//
//    Get your copy from here:
//
//       https://github.com/johnwinans/7SegLED
//       
// ****************************************************************************

include <skew.scad>

ledLen=100/6;           // length of each LED in the strip
ledWidth=10;            // width of one LED strip
wallThickness=1.3;      // the thickness of the segment side-walls
dividerWidth=1.2;       // the width of the strip-divider
dividerHeight=1.5;      // the height of the strip-divider
slotWidth=ledWidth+.75; // the width of the slot needed for an LED strip
segNumLedStrips=2;      // how many LED strips per segment
segNumStripLeds=3;      // how many LEDs per strip
wireHoleSize=4.5;

segInsideWidth = segNumLedStrips*slotWidth+(segNumLedStrips-1)*dividerWidth;   // gross segment inside width
segOutsideWidth = segInsideWidth+2*wallThickness; // gross segment outside width

segInsideLength = segNumStripLeds*ledLen;         // inside length (w/o end-caps)
segOutsideLength = segInsideLength+2*(tan(45/2)*wallThickness);   // outside length (w/o end-caps)

segBackThickness=1.2;   // The thickness of the back
segBackDepth=5;         // How deep to make the LED strip slots
segFrontThickness=1.2;  // The thickness of the front (face of the diffuser)
segFrontDepth=13;       // how deep to make the front

segGrossBackZ = segBackDepth+segBackThickness;    // Gross Z-height of the back
segGrossFrontZ = segFrontDepth+segFrontThickness; // Gross Z-height of the front 



// Uncomment ONE of the following lines to render either the front or back
//skew([6,0,0,0,0,0]) back7();
//skew([-6,0,0,0,0,0]) front7();

//front();
skew([6,0,0,0,0,0]) back();



/**
* One complete 7-segment front/diffuser.
************************************************************************/
module front7()
{
    rotate([0,0,90]) front();
    translate([0,(segOutsideLength+segOutsideWidth),0]) rotate([0,0,90]) front();
    translate([0,-(segOutsideLength+segOutsideWidth),0]) rotate([0,0,90]) front();
    
    translate([-(segOutsideLength/2+segOutsideWidth/2)+.0001,(segOutsideLength/2+segOutsideWidth/2),0]) front();
    translate([-(segOutsideLength/2+segOutsideWidth/2)+.0001,-(segOutsideLength/2+segOutsideWidth/2),0]) front();
    translate([(segOutsideLength/2+segOutsideWidth/2)-.0001,(segOutsideLength/2+segOutsideWidth/2),0]) front();
        translate([(segOutsideLength/2+segOutsideWidth/2)-.0001,-(segOutsideLength/2+segOutsideWidth/2),0]) front();
}


/**
* One complete 7-segment back.
************************************************************************/
module back7()
{
    rotate([0,0,90]) back(ur=false, ll=false);
    translate([0,(segOutsideLength+segOutsideWidth),0]) rotate([0,0,90]) back(ul=false, ll=false);
    translate([0,-(segOutsideLength+segOutsideWidth),0]) rotate([0,0,90]) back(ur=false, lr=false);
    
    translate([-(segOutsideLength/2+segOutsideWidth/2)+.0001,(segOutsideLength/2+segOutsideWidth/2),0]) back(ur=false, lr=false);
    translate([-(segOutsideLength/2+segOutsideWidth/2)+.0001,-(segOutsideLength/2+segOutsideWidth/2),0]) rotate([0,0,180]) back(ul=false, wireHole=(segNumLedStrips%2==1));
    translate([(segOutsideLength/2+segOutsideWidth/2)-.0001,(segOutsideLength/2+segOutsideWidth/2),0]) back(ul=false, wireHole=true);
        translate([(segOutsideLength/2+segOutsideWidth/2)-.0001,-(segOutsideLength/2+segOutsideWidth/2),0]) back(ul=false, ll=false);
}


/**
* One complete front/diffuser segment.
************************************************************************/
module front()
{
    segment(segInsideWidth, segInsideLength, 
        segOutsideWidth, segOutsideLength, 
        segFrontThickness, segFrontDepth,
        tongue=true);
}


/**
* One complete back segment.
*
* @param wireHole When true, include a hole in the bottom of the segment.
************************************************************************/
module back(ll=true, ul=true, lr=true, ur=true, wireHole=false)
{
    segment(segInsideWidth, segInsideLength, 
        segOutsideWidth, segOutsideLength, 
        segBackThickness, segGrossBackZ,
        groove=true,
        ll=ll, ul=ul, lr=lr, ur=ur, wireHole=wireHole);
    
    for ( x = [-segInsideWidth/2+slotWidth+dividerWidth/2 : slotWidth+dividerWidth : segInsideWidth/2] )
    {
        translate([x,0,dividerHeight/2+segBackThickness]) cube([dividerWidth, segInsideLength, dividerHeight], center=true);
        translate([x,0,dividerHeight+segBackThickness]) scale([1,1,.5]) rotate([90,0,0]) cylinder(d=4, h=segInsideLength-ledLen*.3, center=true, $fn=30);
    }
}


/**
* A single hollow segment.
*
* @param iw The width of the inside (cut-out) portion of the segment.
* @param il The inside length (cap-center to cap-center) of the segment.
* @param ow The outside width of the segment.
* @param ol The outside length (cap-center to cap-center) of the segment.
* @param iz The thickness of the segment back/face.
* @param gz The gross thickness of the segment in the Z axis.
* @param wireHole When true, include a hole in the bottom of the segment.
************************************************************************/
module segment(iw, il, ow, ol, iz, gz, ll=true, ul=true, lr=true, ur=true, wireHole=false, groove=false, tongue=false)
{
    ifl = sqrt((iw*iw)/2);	// the length of one face of an end-cap
    grad=.6;                // groove cylinder radius
    gzoffset=grad*4;        // offset from the top of the back segment to cyl
    gxoffset=iw/2-grad*.1;  // offset into wall from center
    gydim=il/2;             // length of the groove
    
    difference()
    {
        rawSegment(ow, ol, gz);
        translate([0,0,iz]) rawSegment(iw, il, gz);
        
        if (!ll)
            translate([-iw/4,-(il/2+iw/4),gz/2+iz]) rotate([0,0,45]) cube([ifl,ifl,gz], center=true);
        if (!lr)
            translate([iw/4,-(il/2+iw/4),gz/2+iz]) rotate([0,0,45]) cube([ifl,ifl,gz], center=true);
        if (!ul)
            translate([-iw/4,(il/2+iw/4),gz/2+iz]) rotate([0,0,45]) cube([ifl,ifl,gz], center=true);
        if (!ur)
            translate([iw/4,(il/2+iw/4),gz/2+iz]) rotate([0,0,45]) cube([ifl,ifl,gz], center=true);
        
        if (wireHole)
            translate([0,-(il/2+iw/4),-1]) cylinder(d=wireHoleSize, h=iz+2, $fn=20);
        
        if (groove)
        {
            for (a=[0,180])
                rotate([0,0,a])
                    translate([gxoffset,0,gz-gzoffset])
                        rotate([90,0,0])
                            cylinder(r=grad, h=gydim, center=true, $fn=20);
        }
    }
    
    if (tongue)
    {
        x=ow-iw;        // tounge bracket width
        y=gydim-2;      // tongue bracket length 
        z=2*(gzoffset+grad);   // height of the tongue bracket
        wff=.4;
        tff=.25;
        
        for (a=[0,180])
            rotate([0,0,a])
            {
                // the tongue mounting bracket
                difference()
                {
                    translate([iw/2,0,gz]) cube([x,y,z], center=true); 
                    translate([iw/2+x/2-wff,0,gz+z/2]) cube([x,y+1,z], center=true); 
                }
                
                // The tongue
                difference()
                {
                    // the tongue cylinder
                    translate([gxoffset-tff,0,gz+gzoffset]) 
                        rotate([90,0,0])
                            cylinder(r=grad, h=y, center=true, $fn=20);
                    
                    // chamfer the ends of the tongue
                    for (cy=[y/2, -y/2])
                        translate([gxoffset-tff,cy,gz+gzoffset-grad])
                            rotate([0,0,-45])
                                cube([grad*2,grad*2,grad*2]);
                }
                
                // add a 1/4-round base to the inside wall under the bracket
                translate([iw/2,0,gz-z/2])
                    scale([1,1,1.5])
                        rotate([90,0,0])
                            cylinder(d=x, h=y, center=true, $fn=20);
            }
    }
}


/**
* A solid segment.
*
* @param sw The width of the segment
* @param sl The length of the seg (centers of the cap cubes)
* @param z the thickness of the seg.
************************************************************************/
module rawSegment(sw, sl, z)
{
    cfl = sqrt((sw*sw)/2);	// the length of one face of an end-cap
    
    hull()
    {
        translate([0,sl/2,z/2]) rotate([0,0,45]) cube([cfl,cfl,z], center=true);
        translate([0,-sl/2,z/2]) rotate([0,0,45]) cube([cfl,cfl,z], center=true);
    }
}
