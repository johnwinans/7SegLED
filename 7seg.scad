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

ledLen=100/6;           // length of each LED in the strip
ledWidth=10;            // width of one LED strip
wallThickness=1.3;      // the thickness of the segment side-walls
dividerWidth=1.2;       // the width of the strip-divider
dividerHeight=1.5;      // the height of the strip-divider
slotWidth=ledWidth+.75; // the width of the slot needed for an LED strip
segNumLedStrips=2;      // how many LED strips per segment
segNumStripLeds=5;      // how many LEDs per strip
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

back();
//front();

*difference()
{
    back();
    translate([0,-50,0])cube([100,100,100], center=true);
}



/**
* One complete front/diffuser segment.
************************************************************************/
module front()
{
    segment(segInsideWidth, segInsideLength, 
        segOutsideWidth, segOutsideLength, 
        segFrontThickness, segFrontDepth);
}


/**
* One complete back segment.
************************************************************************/
module back()
{
    segment(segInsideWidth, segInsideLength, 
        segOutsideWidth, segOutsideLength, 
        segBackThickness, segGrossBackZ);
    
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
************************************************************************/
module segment(iw, il, ow, ol, iz, gz)
{
    difference()
    {
        rawSegment(ow, ol, gz);
        translate([0,0,iz]) rawSegment(iw, il, gz);
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
