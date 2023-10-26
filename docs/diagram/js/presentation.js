var current_slide = 1;
var current_step = 0;

var slides;

$(document).ready(function () {
   loadPresentation();
});
  

function loadPresentation() {
    // Load the svg diagram  
    var s = Snap('#presentation');

    var canvas1 = s.select('#canvas1');
    var elem_current_slide = $('#current_slide')
    var reset_scale = [1,1];
    var transform_speed = 1000;
    var opacity_speed = 700;
    var popover_showing = false;
  
    var layers = s.selectAll('g[id^="layer-"]');
    var exclude_layers = s.selectAll('g[id^="layer-content-"]');
  
    // Setup bootstrap popovers
    $('svg [data-toggle="popover"]').popover({
      'trigger':'manual',
      'container': 'body',
      'white-space': 'nowrap',
      'delay': 1000,
      'html':'true'
    });

    function loadSlide(slide) {
        // If no list of visible ids was passed, show all layers
        if (slide['visible'] == null) {
            slide['visible'] = [];
            $.each(layers, function(index, layer) {
                // don't show layers in exclude_layers
                if ($.inArray(layer, exclude_layers) == -1) {
                    slide['visible'].push(layer.node.id);
                }
            });
        }
  
        // Animate layer opacity
        slide_opacity_speed = slide['opacity_speed'];
        if (slide_opacity_speed == null) {
            slide_opacity_speed = opacity_speed;
        }
        $.each(layers, function(index, layer) {
            if ($.inArray(layer.node.id, slide['visible']) == -1) {
                layer.animate({opacity: 0}, slide_opacity_speed);
            } else {
                layer.animate({opacity: 1}, slide_opacity_speed);
            }
        });
  
        // Hide all popovers in the entire svg diagram
        $('svg [data-toggle="popover"]').popover('hide');
 
        // If a step_layer was provided, set step opacity
        if (slide['step_layer'] != null) {
            step_class = slide['step_class'];
            if (step_class == null) {
                step_class = 'step';
            }
            steps = s.select('#' + slide['step_layer']).selectAll('g.' + step_class);
  
            // If step class is an override, hide all .step classes
            if (step_class != 'step') {
                s.select('#' + slide['step_layer']).selectAll('g.step').animate({opacity: 0},1);
            }
            
  
            // If current_step is 0, hide everything without animation
            if (current_step == 0) {
                steps.animate({opacity: 0},1);
                // Show any popovers in the step_layer but not in a step
                $('#' + slide['step_layer'] + ' [data-toggle="popover"]').not('.step[data-toggle="popover"],.step [data-toggle="popover"]').popover('show');
            } else {
                // Now, animate the show/hide
                $.each(steps, function(index, step) {
                    popovers = $(step.node).find('[data-toggle="popover"]').andSelf();
                    if (index == current_step - 1) {
                        popovers.popover('show');
                    } else {
                        popovers.popover('hide');
                    }
                    if (index >= current_step) {
                        step.animate({opacity: 0}, slide_opacity_speed);
                    } else {
                        step.animate({opacity: 1}, slide_opacity_speed);
                    }
                });
            }
        }

        t = Snap.matrix();
        
        // translate (slide) the canvas
        if (slide['translate'] != null) {
            // If x is set to 'center', automatically center the image in the viewbox
            if (slide['translate'][0] == 'center') {
                current_width = canvas1.getBBox()['width'];
                current_transform = canvas1.attr('transform')['string'].replace('m','').split(',');
                current_scale_x = current_transform[0];
  
                if (current_scale_x != "") {
                    new_width = (current_width / current_scale_x);
                } else {
                    new_width = current_width;
                }
  
                // If we are scaling for this slide, calculate the width at completion of scaling
                if (slide['scale'] != null) {
                    new_width = new_width * slide['scale'][0];
                }
  
                viewbox_width = s.node.viewBox.baseVal.width;
                
                translate_x = (viewbox_width - new_width) / 2;
  
                t.translate(translate_x, slide['translate'][1]);
            } else {
                t.translate(slide['translate'][0], slide['translate'][1]);
            }
        }
  
        // scale the canvas
        if (slide['scale'] != null) {
            t.scale(slide['scale'][0], slide['scale'][1]);
        }
  
        slide_transform_speed = slide['transform_speed'];
        if (slide_transform_speed == null) {
            slide_transform_speed = transform_speed;
        }
        canvas1.animate({transform: t}, slide_transform_speed);
  
        current_step_display = current_step + 1;
        elem_current_slide.text('Slide '+current_slide+' of '+slides.length+' - Step '+ current_step_display );
    }
  
    function nextSlide() {
        slide = slides[current_slide - 1];
  
        // If a slide is configured to step through steps inside the layer
        if (slide['step_layer'] != null) {
            // Allow override of step class per slide, default to .step
            step_class = slide['step_class'];
            if (step_class == null) {
                step_class = 'step';
            }
            steps = s.select('#' + slide['step_layer']).selectAll('g.' + step_class);
            if (steps.length > current_step) {
                current_step += 1;
                loadSlide(slides[current_slide - 1]);
                return;
            }
        }
  
        // If we are not stepping through steps in the layer or if we are at the last step already
        if (slides.length > current_slide) {
            current_slide += 1;
            current_step = 0;
        }
  
        loadSlide(slides[current_slide - 1]);
    }
  
    function previousSlide() {
        slide = slides[current_slide - 1];

        // If a slide is configured to step through steps inside the layer
        if (slide['step_layer'] != null) {
            // Allow override of step class per slide, default to .step
            step_class = slide['step_class'];
            if (step_class == null) {
                step_class = 'step';
            }
            steps = s.select('#' + slide['step_layer']).selectAll('g.' + step_class);
            if (current_step > 0) {
                current_step -= 1;
                loadSlide(slides[current_slide - 1]);
                return;
            }
        }

        // If we are not stepping through steps in the layer or if we are at the first step already
        if (current_slide > 1) {
            current_slide -= 1;

            // Since we're stepping backward, we need to set current_step to the last step if configured
            slide = slides[current_slide - 1];
            if (slide['step_layer'] != null) {
                // Allow override of step class per slide, default to .step
                step_class = slide['step_class'];
                if (step_class == null) {
                    step_class = 'step';
                }
                steps = s.select('#' + slide['step_layer']).selectAll('g.' + step_class);
                current_step = steps.length;
            } else {
                current_step = 0;
            }
        }
        loadSlide(slides[current_slide - 1]);
    }

    // Load the first slide 
    loadSlide(slides[current_slide - 1]); 
  
    // Slide Navigation
    // ----------------
    // Arrow Keys
    $('html').keydown(function (e) {
        // Handle right arrow (forward)
        if (e.which == 39) {
            nextSlide();
        }
        // Handle left arrow (back)
        if (e.which == 37) {
            previousSlide();
        }
    });
    
    // Touch Swipe
    $("#svg-wrapper").swipe( {
        swipeRight:function(event, direction, distance, duration, fingerCount, fingerData) {
            nextSlide();
        },
        swipeLeft:function(event, direction, distance, duration, fingerCount, fingerData) {
            previousSlide();
        },
    });
  
}
