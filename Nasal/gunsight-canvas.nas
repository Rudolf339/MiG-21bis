

var input = {
    gunsight_power : "/fdm/jsbsim/electric/output/gunsight",
    
    fixednetswitch : "/controls/armament/gunsight/fixed-net-power-switch",
    redpath : "/controls/armament/gunsight/red",
    bluepath : "/controls/armament/gunsight/blue",
    greenpath : "/controls/armament/gunsight/green",
    fixed_net_alphapath : "/controls/armament/gunsight/fixed-net-brightness-knob",
    fontsizepath : "/controls/armament/gunsight/font-size",
    linewidthpath : "/controls/armament/gunsight/thickness",
    viewX : "/sim/current-view/x-offset-m",
    viewY : "/sim/current-view/y-offset-m",
    viewZ : "/sim/current-view/z-offset-m",
    ghosting_x : "/controls/armament/gunsight/ghosting-x",
    ghosting_y : "/controls/armament/gunsight/ghosting-y",
    scaling : "/controls/armament/gunsight/scaling",
    sight_align_elevation : "/controls/armament/gunsight/elevation",
    sight_align_windage : "/controls/armament/gunsight/windage",
    
    #pipper modes and info
    pipperpowerswitch : "/controls/armament/gunsight/pipper-power-switch",
    pipperscale : "/controls/armament/gunsight/pipper-scale",
    pipperaccuracy : "/controls/armament/gunsight/pipper-accuracy-switch",
    pippergunmissile : "/controls/armament/gunsight/gun-missile-switch",
    pippermode : "/controls/armament/gunsight/pipper-mode-select-switch",
    targetsizeknob : "/controls/armament/gunsight/target-size-knob",
    pipperangularcorrection : "/controls/armament/gunsight/pipper-angular-correction-knob",
    pipperbrightness : "/controls/armament/gunsight/pipper-brightness-knob",
    pipperautomanual : "/controls/armament/gunsight/auto-man-switch",
    
    air_gnd_switch : "/controls/armament/panel/air-gnd-switch",
    ir_sar_switch : "/controls/armament/panel/ir-sar-switch",
    gun_missile_switch : "/controls/armament/gunsight/gun-missile-switch",
};

foreach(var name; keys(input)) {
    input[name] = props.globals.getNode(input[name], 1);
}

var gun_sight = {

    canvas_settings: {
        "name": "gunsight",
        "size": [1024, 1024],
        "view": [1024, 1024],
        "mipmapping": 1
    },
    
    new: func(placement) {
        var m = {parents: [gun_sight]};
        m.gunsight = canvas.new(gun_sight.canvas_settings);
        m.gunsight.addPlacement(placement);
        m.gunsight.setColorBackground(0,0,0,0);
        
        m.dR = m.normColor(input.redpath.getValue());
        m.dG = m.normColor(input.greenpath.getValue());
        m.dB = m.normColor(input.bluepath.getValue());
        m.dAf = input.fixed_net_alphapath.getValue();
        m.dAp = input.pipperbrightness.getValue();
        m.fS = input.fontsizepath.getValue();
        #m.lW = input.linewidthpath.getValue();
        m.lW = 3;
        
        # calculate pixel per degree
        # x and z coords of the center of the hud
        m.gsight_x = -4.08292;
        m.gsight_z = 1.07701;
        
        m.gsight_height_m = 0.17; # height of hud in meters
        m.gsight_height_px = 920; # actual height of gunsight in pixels
        
        m.mil = m.calcPixelPerDegree(-3.33, 1.2813)[2];
        
        m.center_offset_px = 288;

        # for scaling later
        m.base_distance = input.viewX.getValue() - m.gsight_x;
        m.old_sca = 0;
        
        ###########
        # FIXED NET
        ###########
        
        # specs:
        # center is even with aircraft point of aim
        # top bar is 40 mils above center, 6 mils wide
        # second bar is 20 mils above center, 6 mils wide
        # center bar has 4 vertical bars, spaced at -40, -20, 20, and 40, 5 mils tall
        # there are 4 horizontal bars, with left edges at
        # 3 horizontal bars, at 10, 20, 30 mils below center, 6 mils long with a 2.5 gap to center - | -
        # alternating 12 mil bars (4) and 6 mil bars (3) thereafter

        #m.fixed_net = m.gunsight.createGroup()
        m.fixed_net = m.gunsight.createGroup();
        m.fixed_net_lines = m.fixed_net.createChild("path","fixed_net")
            .setColor(m.dR,m.dG,m.dB,m.dAf)
            .setStrokeLineWidth(m.lW)
            .setStrokeLineCap("round")
            .move( 0            ,-45 * m.mil  ) # top of verticle line
            .line( 0            , 48 * m.mil  ) # down just past center
            .move(-3    * m.mil ,-43 * m.mil  ) # to first horiz line on top
            .line( 6    * m.mil ,  0          )
            .move(-6    * m.mil , 20 * m.mil  ) # move to the second horiz line
            .line( 6    * m.mil ,  0          )
            .move(-23   * m.mil , 20 * m.mil  ) # far left center horiz loie
            .line( 6    * m.mil , 0           )
            .move( 3    * m.mil , 0           )
            .line( 6    * m.mil , 0           )
            .move( 10   * m.mil , 0           )
            .line( 6    * m.mil , 0           )
            .move( 3    * m.mil , 0           )
            .line( 6    * m.mil , 0           )
            .move(-60   * m.mil ,-3  * m.mil  ) # vertical lines near the center
            .line( 0            ,  6  * m.mil )
            .move( 20   * m.mil , -5  * m.mil )
            .line( 0            ,  4  * m.mil )
            .move( 40   * m.mil , -4  * m.mil )
            .line( 0            ,  4  * m.mil )
            .move( 20   * m.mil , -5  * m.mil )
            .line( 0            ,  6  * m.mil )
            .move(-40   * m.mil ,  4  * m.mil ) # do vertical lines w/ gaps below center, all the way down
            .line( 0            ,  8   * m.mil)
            .move( 0            ,  1   * m.mil)
            .line( 0            ,  8   * m.mil)
            .move( 0            ,  4   * m.mil)
            .line( 0            , 87   * m.mil)
            .move(-6    * m.mil ,-15   * m.mil) # do remainder of center horizontal lines
            .line( 12   * m.mil , 0           )
            .move(-9    * m.mil , -10  * m.mil)
            .line( 6    * m.mil , 0           )
            .move(-9    * m.mil ,-10   * m.mil)
            .line( 12   * m.mil , 0           )
            .move(-9    * m.mil , -10  * m.mil)
            .line( 6    * m.mil , 0           )
            .move(-9    * m.mil ,-10   * m.mil)
            .line( 12   * m.mil , 0           )
            .move(-9    * m.mil , -10  * m.mil)
            .line( 6    * m.mil , 0           )
            .move(-9    * m.mil ,-10   * m.mil)
            .line( 12   * m.mil , 0           )
            .move(-13.5 * m.mil , -10  * m.mil)
            .line( 5    * m.mil , 0           )
            .move( 5    * m.mil , 0           )
            .line( 5    * m.mil , 0           )
            .move(-15   * m.mil , -10  * m.mil)
            .line( 5    * m.mil , 0           )
            .move( 5    * m.mil , 0           )
            .line( 5    * m.mil , 0           )
            .move(-15   * m.mil , -10  * m.mil)
            .line( 5    * m.mil , 0           )
            .move( 5    * m.mil , 0           )
            .line( 5    * m.mil , 0           )
            .move(-27.5 * m.mil , 10   * m.mil) # 45 degree bars
            .line(-55   * m.mil , 55   * m.mil)
            .move(150   * m.mil , 0           )
            .line(-55   * m.mil ,-55   * m.mil)
            .move(-40   * m.mil , 25   * m.mil)
            .line(-6.66 * m.mil , 19* m.mil) # 22.5 degree bars w/ gaps
            .move(-6.66 * m.mil , 19* m.mil)
            .line(-6.66 * m.mil , 19* m.mil)
            .move(79.98 * m.mil , 0           )
            .line(-6.66 * m.mil ,-19* m.mil)
            .move(-6.66 * m.mil ,-19* m.mil)
            .line(-6.66 * m.mil ,-19* m.mil);

        m.fixed_net_inner_arch = m.fixed_net.createChild("path","fixednetarch1")
            .setColor(m.dR,m.dG,m.dB,m.dAf)
            .setStrokeLineWidth(m.lW)
            .setStrokeLineCap("round")
            # 207.34 mils long
            .setStrokeDashArray([19.5 * m.mil,
                                3 * m.mil,
                                12 * m.mil,
                                3 * m.mil,
                                12 * m.mil,
                                3 * m.mil,
                                12 * m.mil,
                                3 * m.mil,
                                12 * m.mil,
                                3 * m.mil,
                                12 * m.mil,
                                18 * m.mil,
                                12 * m.mil,
                                3 * m.mil,
                                12 * m.mil,
                                3 * m.mil,
                                12 * m.mil,
                                3 * m.mil,
                                12 * m.mil,
                                3 * m.mil,
                                12 * m.mil,
                                3 * m.mil,
                                19.5 * m.mil,
                                ])
            .move(-60 * m.mil * math.cos(9 * D2R),-10 * m.mil)
            .arcLargeCCW(60 * m.mil, 60 * m.mil,0,120 * m.mil * math.cos(9 * D2R),0);

        m.fixed_net_outer_arch = m.fixed_net.createChild("path","fixednetarch2")
            .setColor(m.dR,m.dG,m.dB,m.dAf)
            .setStrokeLineWidth(m.lW)
            .setStrokeLineCap("round")
            .setStrokeDashArray([16 * m.mil,
                                5 * m.mil,
                                15 * m.mil,
                                5 * m.mil,
                                15 * m.mil,
                                5 * m.mil,
                                15 * m.mil,
                                26 * m.mil,
                                15 * m.mil,
                                5 * m.mil,
                                15 * m.mil,
                                5 * m.mil,
                                15 * m.mil,
                                5 * m.mil,
                                16 * m.mil,
                                ])
            .move(-100 * m.mil * math.cos(39 * D2R), 100 * m.mil * math.sin(39 * D2R))
            .arcSmallCCW(100 * m.mil, 100 * m.mil, 0, 200 * m.mil * math.cos(39 * D2R),0);

        m.fixed_net.setTranslation(512,512 - m.center_offset_px);
        
        ###########
        # PIPPER
        ###########
        
        # specs:
        # center is 2 mil dot
        # diamond is 5 mils end to end, 2 mils wide
        
        m.pipper = m.gunsight.createGroup();
        m.pipper_elems = [];
        m.pipper_center = m.pipper.createChild("path", "center")
            .moveTo(-m.mil,0)
            .arcSmallCW(m.mil, m.mil, 0, m.mil * 2, 0)
            .arcSmallCW(m.mil, m.mil, 0,-m.mil * 2, 0)
            .setColor(m.dR,m.dG,m.dB,m.dAp)
            .setColorFill(m.dR, m.dG, m.dB, m.dAp);
         
        for (var i = 0; i < 8; i = i + 1) {
            append(m.pipper_elems, m.pipper.createChild("path", "diamond" ~ i)
                .line(-m.mil * 3.3, m.mil)
                .line(-m.mil * 1.7,-m.mil)
                .line( m.mil * 1.7,-m.mil)
                .line( m.mil * 3.3, m.mil)
                .setStrokeLineCap("round")
                .setColor(m.dR,m.dG,m.dB,m.dAp)
                .setColorFill(m.dR, m.dG, m.dB, m.dAp)
                .setRotation(i * 45 * D2R, 0));
        }
        m.pipper.setTranslation(512,512);
        m.pipper.hide();
        return m;
    },
    
    calcPixelPerDegree: func(view_x = 0, view_z = 0) {
        
        # angle from view to center of hud
        # x is forward/back, z is up/down
        # in the view props, y is up/down, z is forward/back
        me.z_delta = (view_z == 0 ? input.viewY.getValue() : view_z) - me.gsight_z;
        me.x_delta = (view_x == 0 ? input.viewZ.getValue() : view_x) - me.gsight_x;
        me.view_dist = math.sqrt(me.z_delta * me.z_delta + me.x_delta * me.x_delta);
        me.angle_to_hud = (90 * D2R) - math.asin(me.x_delta / me.view_dist);
        
        me.z_to_bottom_delta = me.z_delta + (me.gsight_height_m / 2);
        me.hypot_to_bottom = math.sqrt(me.z_to_bottom_delta * me.z_to_bottom_delta + me.x_delta * me.x_delta);
        me.angle_to_bottom = (90 * D2R) - math.asin(me.x_delta / me.hypot_to_bottom);
        
        me.px_per_degree = (me.gsight_height_px / 2) / (math.abs(me.angle_to_bottom - me.angle_to_hud) * R2D);
        me.px_per_moa = me.px_per_degree / 60;
        me.px_per_mil = me.px_per_degree * 0.05625;
        #print(me.px_per_degree);
        #print(me.px_per_moa);
        #print(me.px_per_mil);
        return [me.px_per_degree, me.px_per_moa, me.px_per_mil];
    },
    
    scalePaths: func() {
        me.sca = (input.viewX.getValue() - me.gsight_x) / me.base_distance;
        if (me.old_sca != me.sca) {
            me.fixed_net.setScale(me.sca, me.sca);
            me.pipper.setScale(me.sca, me.sca);
        }
        me.old_sca = me.sca;
    },
    
    normColor: func(val) {
        return math.clamp(val / 255,0,1);
    },
};

var gs = 0;

var init = setlistener("/sim/signals/fdm-initialized", func() {
  removelistener(init); # only call once
  gs = gun_sight.new({"node": "sight"});
});