//***************************************************************************
//
//    COPYRIGHT (C) 2017 JOHN WINANS
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
//    along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//    Get your copy from here:
//
//       https://github.com/johnwinans/7SegLED
//
//***************************************************************************

iDia=23;            // the inside diameter of the dot
wallthick=2;        // the outside wall thickness of the dot
backz=1;            // the thickness of the base
facez=1;            // the thickness of the face
hollowzb=5;         // the 'hollow' inside depth of the back
hollowzf=13;        // the 'hollow' inside depth of the front

ledff=.5;           // a fudge-factor for the LED dimensions
ledlen=100/6;       // length of one LED on the strip
ledwidth=10;        // width of the LED strip (not including the fudge factor)

$fa=1;              // select a reasonable resolution
$fs=.7;             // select a reasonable resolution


// uncomment one of the following to render a front or back:
back();             // render the back
//front();            // render the front




module front()
{
    dot(iDia, wallthick, hollowzf, facez, tongue=true);
}

module back()
{
    dot(iDia, wallthick, hollowzb, backz, groove=true, access=true, align=true);
}

/**
* Render a dot with optional tongue, groove and/or LED strip retainer.
*
* @param id The inside diameter of the dot cylinder
* @param wt The outter-wall thickness of the dot
* @param iz The inside Z-dimension (how much it is to be hollowed out)
* @param bz The face/back Z-dimension (how thick the face or back is to be)
* @param tongue If true then include a snap-together tongue
* @param groove If true then include a groove for the tongue to snap into
* @param access If true then include an access hole for wires
* @param align If true include a retainer to hold the LED strip
*****************************************************************************/
module dot(id, wt, iz, bz, tongue=false, groove=false, access=false, align=false)
{
    od=id+2*wt;     // outside diameter of the dot
    oz=iz+bz;       // Z-height of the dot (not including an optional tongue)

    tff=.2;         // printing fudge-factor for tongue allowance
    tzff=.5;        // extra height added to the groove slot so tongue will fit
    tod=id-tff*2;   // OD of the tongue
    tid=tod-2*wt;   // ID of the tongue
    tlen=3;         // z-height of the tongue
    tlipz=1;        // z-height of the lip
    tlipx=1;        // how far the lip sticks out from the tongue in the x-axis
    tzoverlap=wt;   // how far the tongue overlaps the 'inside' of the dot cylinder
 
    accessDia=5;    // access hole diameter (for wires)
    
    alignz=1;       // how tall the LED alignment box is
    alignwt=1.3;    // how thick the walls of the LED alignment box are
    retainz=1;      // the height of the retainer
    retainff=.5;    // how far to cover the LED with the retainer
    
    difference()
    {
        cylinder(d=od, h=oz);           // the main outer body of the dot
        translate([0,0,oz-iz]) cylinder(d=id, h=iz+.1); // remove the inside space (make it hollow)

        if (groove)
        {
            // a groove around the inside of the back to let the front sanap into the back
            translate([0,0,oz-tlen-tzff]) cylinder(d=id+tlipx, h=tlipz+tzff*2);
        }

        if (access)
        {
            // a hole for wire access
            translate([id/2-accessDia/2, 0,-.1]) cylinder(d=accessDia, h=bz+.2);
        }
    }

    
    if (align)
    {
        // some lines to align the LED strip against the back
        translate([0, 0, bz+alignz/2-.01])
        difference()
        {
            cube ([ledwidth+ledff+alignwt*2, ledlen+ledff+alignwt*2, alignz+.01], center=true);
            cube ([ledwidth+ledff, ledlen+ledff, alignz+.02], center=true);
        }
        
        // a retaining lip along the top
        translate([0, 0, bz+alignz+retainz/2-.01])
        difference()
        {
            cube ([ledwidth+ledff+alignwt*2, ledlen-3, retainz], center=true);
            cube ([ledwidth-retainff, ledlen-3+.02, retainz+.02], center=true);
        }
    }

    
    if (tongue)
    {
        intersection()
        {
            union()
            {
                // the tongue
                translate([0,0,oz-tzoverlap])
                difference()
                {
                    union()
                    {
                        cylinder(d=tod, h=tlen+tzoverlap);      // outside
                        cylinder(d=od, h=tzoverlap);            // fill the tff gap
                    }
                    translate([0,0,-.1])
                    {
                        cylinder(d=tid, h=tlen+tzoverlap+.2);   // remove the inside
                        cylinder(d1=id, d2=tid, h=tzoverlap);   // put a wedge on the bottom (easier printing)
                    }
                }
        
                // a rim around the tip of the tongue
                translate([0,0,oz+tlen-tlipz])
                {
                    difference()
                    {
                        cylinder(d=tod+.7, h=tlipz);                    // the rim
                        translate([0,0,-.1]) cylinder(d=tid, h=tlipz+.2);   // hollow out the rim cylinder
                    }
                }
        
            } // union
            
            // remove some of the tongue so that it only has two ends
            translate([-od/2,-od/6,oz-tzoverlap-.01]) cube([od, od/3, oz+tlen+tzoverlap+.02]);
            
        } // intersection
    }
}
