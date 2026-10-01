// Data section for constants and global variables
.data

// External import strings
.extern __NSConcreteGlobalBlock

// Common
cls_NSString:   .asciz "NSString"

s_alloc:        .asciz "alloc"
s_init:         .asciz "init"
s_utf8:         .asciz "stringWithUTF8String:"

t_quit:         .asciz "Quit"
k_quit:         .asciz "q"

s_characters:   .asciz "characters"
s_charCodeAt:   .asciz "characterAtIndex:"


// Application methods
cls_NSApp:      .asciz "NSApplication"
cls_NSMenu:     .asciz "NSMenu"
cls_NSMenuItem: .asciz "NSMenuItem"

s_sharedApp:    .asciz "sharedApplication"
s_setPol:       .asciz "setActivationPolicy:"
s_setMenu:      .asciz "setMainMenu:"
s_addItem:      .asciz "addItem:"
s_setSub:       .asciz "setSubmenu:"
s_setTarget:    .asciz "setTarget:"
s_run:          .asciz "run"
s_makeKey:      .asciz "makeKeyAndOrderFront:"
s_terminate:    .asciz "terminate:"
s_contentView:   .asciz "contentView"
s_frame:         .asciz "frame"
s_convertPoint: .asciz "convertPoint:fromView:"

// Window methods
cls_NSWindow:   .asciz "NSWindow"

s_initTitle:    .asciz "initWithTitle:action:keyEquivalent:"
s_setTitle:     .asciz "setTitle:"
zpWindowTitle:          .asciz "ARMPaint" // WINDOW TITLE


// Event methods
cls_NSEvent:    .asciz "NSEvent"

s_addMon:       .asciz "addLocalMonitorForEventsMatchingMask:handler:"
zpEventsScreenMouseLocation:      .asciz "locationInWindow"

// Rendering methods
cls_NSGraphicsContext: .asciz "NSGraphicsContext"
cls_NSView:     .asciz "NSView"

zpBasicView:     .asciz "zpBasicView"

s_initRect:     .asciz "initWithContentRect:styleMask:backing:defer:"
s_drawRect:     .asciz "drawRect:"
s_initWithFrame: .asciz "initWithFrame:"
s_setCtxView:   .asciz "setContentView:"
s_currCtx:      .asciz "currentContext"
s_CGContext:    .asciz "CGContext"
s_setNeedsDisplay: .asciz "setNeedsDisplay:"
zpDrawRectSignature:  .asciz "v@:{CGRect={CGPoint=dd}{CGSize=dd}}"

s_drawAtPoint: .asciz "drawAtPoint:withAttributes:"


// Global variables
.p2align 3
zpWindowPosition: .double 0.0, 0.0
zpViewPtr:        .quad 0

zpWindowExtents:    .double 500, 200.0, 640, 640.0 // WINDOW RECT {x, y, width, height}
zpCurrentTool: .int 0 // 0 = pen, 1 = eraser
zpCurrentColor:     .double 1.0, 0.0, 0.0, 1.0 // selected color

zpGridArray: .skip 1024  // 1024 pixels, 32x32 grid, 1 byte per pixel
zpGridColorArray: .skip 32768 // 1024 pixels * 4 doubles per color (RGBA)
zpGridSize:  .int 32 // number of cells in grid width and height
zpCellPixelSize: .int 10 // number of pixels per grid cell (10x10 pixel cells)

// predefined colors
.align 3

color1:
    .double 0.0,   0.0,   0.0,   1.0

color2:
    .double 0.114, 0.169, 0.325, 1.0

color3:
    .double 0.494, 0.145, 0.325, 1.0

color4:
    .double 0.0,   0.529, 0.318, 1.0

color5:
    .double 0.671, 0.322, 0.212, 1.0

color6:
    .double 0.373, 0.341, 0.310, 1.0

color7:
    .double 0.761, 0.765, 0.780, 1.0

color8:
    .double 1.0,   0.945, 0.910, 1.0

color9:
    .double 1.0,   0.0,   0.302, 1.0

color10:
    .double 1.0,   0.639, 0.0,   1.0

color11:
    .double 1.0,   0.925, 0.153, 1.0

color12:
    .double 0.0,   0.894, 0.212, 1.0

zpColorPalette: 
    .double 0.0,   0.0,   0.0,   1.0   // color 1
    .double 0.114, 0.169, 0.325, 1.0   // color 2
    .double 0.494, 0.145, 0.325, 1.0   // color 3
    .double 0.0,   0.529, 0.318, 1.0   // color 4
    .double 0.671, 0.322, 0.212, 1.0   // color 5
    .double 0.373, 0.341, 0.310, 1.0   // color 6
    .double 0.761, 0.765, 0.780, 1.0   // color 7
    .double 1.0,   0.945, 0.910, 1.0   // color 8
    .double 1.0,   0.0,   0.302, 1.0   // color 9
    .double 1.0,   0.639, 0.0,   1.0   // color 10
    .double 1.0,   0.925, 0.153, 1.0   // color 11
    .double 0.0,   0.894, 0.212, 1.0    // color 12


helloStr: .asciz "ZPaint in ARM64 Assembly"



// Function pointers for event handlers
.p2align 3
zpEventBlockLiteralKeyDown:
    .quad __NSConcreteGlobalBlock
    .int  0x10000000
    .int  0
    .quad zpBlockHandlerKeyDown
    .quad zpBlockDescriptor

zpEventBlockLiteralDrag:
    .quad __NSConcreteGlobalBlock
    .int  0x10000000
    .int  0
    .quad zpBlockHandlerDrag
    .quad zpBlockDescriptor

zpBlockDescriptor:
    .quad 0
    .quad 32         
    .quad 0          // copy helper (not used)
    .quad 0          // dispose helper (not used)


// Text section for code
.text

.globl _main
.globl zpCmdDrawRect


// functions for tool updates
.p2align 2
set_pen:
    mov w21, #0
    b update_tool

set_eraser:
    mov w21, #1
    b update_tool

update_tool:
    adrp x8, zpCurrentTool@PAGE
    str  w21, [x8, zpCurrentTool@PAGEOFF]
    b handler_exit   // return to OS after updating tool


// NSEvent handlers
zpBlockHandlerKeyDown:
    stp x29, x30, [sp, #-64]! 
    mov x29, sp
    stp x19, x20, [sp, #32] 
    stp x21, x22, [sp, #48]

    mov x19, x1    // x1 is the NSEvent object

    // get the 'characters' NSString from the event
    adrp x0, s_characters@PAGE
    add  x0, x0, s_characters@PAGEOFF
    bl _sel_registerName
    mov x1, x0 
    mov x0, x19 
    bl _objc_msgSend   // Returns NSString* in x0
    mov x20, x0        // Save NSString

    
    adrp x0, s_charCodeAt@PAGE
    add  x0, x0, s_charCodeAt@PAGEOFF
    bl _sel_registerName // call sel_registerName("characterAtIndex:"), result of first character is in x0
    mov x1, x0
    mov x0, x20        
    mov x2, #0         
    bl _objc_msgSend   // returns the character (unichar) in x0
    
    cmp w0, #98  // #98 is ASCII b
    b.eq set_pen
    cmp w0, #101     // #101 is ASCII e
    b.eq set_eraser
    cmp w0, #118  // #118 is ASCII v
    b.eq zpColor1
    cmp w0, #99  // #99 is ASCII c
    b.eq zpColor2
    cmp w0, #114  // #114 is ASCII r
    b.eq zpColor6
    cmp w0, #103  // #103 is ASCII g
    b.eq zpColor7
    cmp w0, #120  // #120 is ASCII x
    b.eq zpColor3
    cmp w0, #121  // #121 is ASCII y
    b.eq zpColor4
    cmp w0, #122  // #122 is ASCII z
    b.eq zpColor5
    cmp w0, #49  // #49 is ASCII 1
    b.eq zpColor8
    cmp w0, #50  // #50 is ASCII 2
    b.eq zpColor9
    cmp w0, #51  // #51 is ASCII 3
    b.eq zpColor10
    cmp w0, #52  // #52 is ASCII 4
    b.eq zpColor11
    cmp w0, #53  // #53 is ASCII 5
    b.eq zpColor12

    bl zpCmdSetColor

    b handler_exit

//rgba(0.000, 0.000, 0.000, 1.0)
//rgba(0.114, 0.169, 0.325, 1.0)
//rgba(0.494, 0.145, 0.325, 1.0)
//rgba(0.000, 0.529, 0.318, 1.0)
//rgba(0.671, 0.322, 0.212, 1.0)
//rgba(0.373, 0.341, 0.310, 1.0)
//rgba(0.761, 0.765, 0.780, 1.0)
//rgba(1.000, 0.945, 0.910, 1.0)
//rgba(1.000, 0.000, 0.302, 1.0)
//rgba(1.000, 0.639, 0.000, 1.0)
//rgba(1.000, 0.925, 0.153, 1.0)
//rgba(0.000, 0.894, 0.212, 1.0)
//rgba(0.161, 0.678, 1.000, 1.0)
//rgba(0.514, 0.463, 0.612, 1.0)
//rgba(1.000, 0.467, 0.659, 1.0)
//rgba(1.000, 0.800, 0.667, 1.0)

zpColor1:
    adrp x0, color1@PAGE
    add  x0, x0, color1@PAGEOFF
    ldp d0, d1, [x0]
    ldp d2, d3, [x0, #16]
    ret

zpColor2:
    adrp x0, color2@PAGE
    add  x0, x0, color2@PAGEOFF
    ldp d0, d1, [x0]
    ldp d2, d3, [x0, #16]
    ret

zpColor3:
    adrp x0, color3@PAGE
    add  x0, x0, color3@PAGEOFF
    ldp d0, d1, [x0]
    ldp d2, d3, [x0, #16]
    ret

zpColor4:
    adrp x0, color4@PAGE
    add  x0, x0, color4@PAGEOFF
    ldp d0, d1, [x0]
    ldp d2, d3, [x0, #16]
    ret

zpColor5:
    adrp x0, color5@PAGE
    add  x0, x0, color5@PAGEOFF
    ldp d0, d1, [x0]
    ldp d2, d3, [x0, #16]
    ret

zpColor6:
    adrp x0, color6@PAGE
    add  x0, x0, color6@PAGEOFF
    ldp d0, d1, [x0]
    ldp d2, d3, [x0, #16]
    ret

zpColor7:
    adrp x0, color7@PAGE
    add  x0, x0, color7@PAGEOFF
    ldp d0, d1, [x0]
    ldp d2, d3, [x0, #16]
    ret

zpColor8:
    adrp x0, color8@PAGE
    add  x0, x0, color8@PAGEOFF
    ldp d0, d1, [x0]
    ldp d2, d3, [x0, #16]
    ret

zpColor9:
    adrp x0, color9@PAGE
    add  x0, x0, color9@PAGEOFF
    ldp d0, d1, [x0]
    ldp d2, d3, [x0, #16]
    ret

zpColor10:
    adrp x0, color10@PAGE
    add  x0, x0, color10@PAGEOFF
    ldp d0, d1, [x0]
    ldp d2, d3, [x0, #16]
    ret

zpColor11:
    adrp x0, color11@PAGE
    add  x0, x0, color11@PAGEOFF
    ldp d0, d1, [x0]
    ldp d2, d3, [x0, #16]
    ret

zpColor12:
    adrp x0, color12@PAGE
    add  x0, x0, color12@PAGEOFF
    ldp d0, d1, [x0]
    ldp d2, d3, [x0, #16]
    ret

// call to set color into zpCurrentColor, by suppliyng RGBA values in d0, d1, d2, d3
zpCmdSetColor:
    adrp x8, zpCurrentColor@PAGE
    add  x8, x8, zpCurrentColor@PAGEOFF
    stp d0, d1, [x8]
    stp d2, d3, [x8, #16]

    b handler_exit

// function to draw text at position passed with x and y in d0 and d1, using the black color
zpDrawText:
    stp x29, x30, [sp, #-64]!
    mov x29, sp

    stp x19, x20, [sp, #16]

    // preserve coords
    fmov d20, d0
    fmov d21, d1

    // NSString class
    adrp x0, cls_NSString@PAGE
    add  x0, x0, cls_NSString@PAGEOFF
    bl _objc_getClass
    mov x19, x0

    // selector stringWithUTF8String:
    adrp x0, s_utf8@PAGE
    add  x0, x0, s_utf8@PAGEOFF
    bl _sel_registerName
    mov x1, x0

    mov x0, x19
    adrp x2, helloStr@PAGE
    add  x2, x2, helloStr@PAGEOFF
    bl _objc_msgSend

    mov x20, x0  // NSString*

    // selector drawAtPoint:withAttributes:
    adrp x0, s_drawAtPoint@PAGE
    add  x0, x0, s_drawAtPoint@PAGEOFF
    bl _sel_registerName
    mov x1, x0

    mov x0, x20

    // restore coords
    fmov d0, d20
    fmov d1, d21

    mov x2, #0
    bl _objc_msgSend

    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #64
    ret
   




zpBlockHandlerDrag:
    stp x29, x30, [sp, #-64]! 
    mov x29, sp
    stp x19, x20, [sp, #32] 
    stp x21, x22, [sp, #48] // Save extra register for math

    mov x19, x1    // move x1 into x19

    adrp x0, zpEventsScreenMouseLocation@PAGE
    add  x0, x0, zpEventsScreenMouseLocation@PAGEOFF
    bl _sel_registerName
    mov x1, x0 
    mov x0, x19 
    bl _objc_msgSend   // Returns {x, y} in d0, d1

    // Save point
    sub sp, sp, #16 // subtract 16 from sp, store in sp
    stp d0, d1, [sp] // store d0, d1 into sp

    // get convertpoint selector
    adrp x0, s_convertPoint@PAGE
    add  x0, x0, s_convertPoint@PAGEOFF
    bl _sel_registerName
    mov x9, x0          // save selector in x9 (safe temp register)

    // load view
    adrp x8, zpViewPtr@PAGE
    ldr  x0, [x8, zpViewPtr@PAGEOFF]   // x0 = view

    // restore selector
    mov x1, x9 // 

    ldp d0, d1, [sp] // load sp into d0, d1
    add sp, sp, #16 // add 16 to sp

    mov x2, #0 // move 0 into x2

    bl _objc_msgSend

    sub sp, sp, #16 // subtract 16 from sp
    stp d0, d1, [sp]  // store d0, d1 into sp     

    adrp x0, s_frame@PAGE
    add  x0, x0, s_frame@PAGEOFF
    bl _sel_registerName // call sel_registerName("frame"), result NSView.frame in x0
    mov x1, x0 // move frame into x1

    adrp x8, zpViewPtr@PAGE
    ldr  x0, [x8, zpViewPtr@PAGEOFF]
    bl _objc_msgSend         // Returns CGRect {x,y,w,h} in d0, d1, d2, d3

    fmov d5, d2      // save width into d5

    // Restore our converted mouse X, Y points
    ldp d0, d1, [sp]         
    add sp, sp, #16

    // calculate offset of grid to be in center of screen horizontally
    fmov d4, #2.0       // move 2.0 into d4 for dividing
    fdiv d5, d5, d4        // d5 = width / d4, d5 = width, d4 = 2.0
    fcvtzs x21, d5         // convert with into int
    sub  x21, x21, #160    // subtract 160 from x21 to get final offset
    scvtf d2, x21          // convert back to double for subtraction later

    // subtract offset from mouse X
    fsub d0, d0, d2        // subtract d2 from d0, d0 = d0 - d2

    // store corrected coordinates
    adrp x8, zpWindowPosition@PAGE
    add  x8, x8, zpWindowPosition@PAGEOFF
    str d0, [x8] // store window position x in d0
    str d1, [x8, #8] // store window positon y in d1

    bl zpDrawPixelAtMouse  // call to draw pixel

    // trigger nsview to redraw
    adrp x0, s_setNeedsDisplay@PAGE
    add  x0, x0, s_setNeedsDisplay@PAGEOFF
    bl _sel_registerName // call sel_registerName("setNeedsDisplay:")
    mov x1, x0 // move the selector of setneeddisplay into x1

    adrp x8, zpViewPtr@PAGE
    ldr  x0, [x8, zpViewPtr@PAGEOFF] // load viewptr into x0
    mov  x2, #1      // move 1 into x2
    bl _objc_msgSend // call to function with args (x0 = viewptr, x1 = setNeedsDisplay, x2 = 1), void

    // cleanup registers
    mov x0, x19  // move 
    ldp x21, x22, [sp, #48]
    ldp x19, x20, [sp, #32] 
    ldp x29, x30, [sp], #64 
    ret


handler_exit:
    mov x0, x19     
    ldp x21, x22, [sp, #48]
    ldp x19, x20, [sp, #32] 
    ldp x29, x30, [sp], #64
    ret



// Rendering function for drawing rectangles
zpCmdDrawRect:
    // Save state: 80 bytes, 16-byte aligned
    stp x29, x30, [sp, #-80]!
    mov x29, sp
    stp x19, x20, [sp, #16]
    stp x21, x22, [sp, #32]
    stp x23, x24, [sp, #48]
    stp x25, x26, [sp, #64]

    mov x24, x0             // save selector for view in x24
    bl zpGetWindowFrame  // get window frame and store in global variable for use in centering grid and text

    adrp x8, zpWindowExtents@PAGE
    add  x8, x8, zpWindowExtents@PAGEOFF
    ldp  d10, d11, [x8]        // d10 = origin.x, d11 = origin.y
    ldp  d12, d13, [x8, #16]   // d12 = width, d13 = height

    // Calculate horizontal center for the 320px grid (32 cells * 10px)
    fmov d4, #2.0
    fdiv d2, d12, d4           // d2 = View Width / 2
    fcvtzs x26, d2             // Convert to integer
    sub  x26, x26, #160        // x26 = start pixel X for the grid

    
    // calculate offset for text
    fmov d0, #31.0                // x = center of screen
    fmov d4, #30.0
    fsub d1, d13, d4           // y = Height - 30px (top margin)
    bl zpDrawText // call label to draw text

    // setup graphics context
    adrp x0, cls_NSGraphicsContext@PAGE
    add  x0, x0, cls_NSGraphicsContext@PAGEOFF
    bl _objc_getClass // call function with args (x0 = NSGraphicsContext string), result is in x0
    mov x19, x0 // move NSGraphicsContext class into x19

    adrp x0, s_currCtx@PAGE
    add  x0, x0, s_currCtx@PAGEOFF
    bl _sel_registerName // call sel_registerName("currentContext"), result is in x0
    mov x1, x0 // move selector for currentContext into x1
    mov x0, x19  // move NSGraphicsContext class into x0
    bl _objc_msgSend        // call function with args (x0 = NSGraphicsContext class, x1 = currentContext selector), result is in x0
    mov x19, x0                // x19 = NSGraphicsContext.currentContext

    adrp x0, s_CGContext@PAGE
    add  x0, x0, s_CGContext@PAGEOFF
    bl _sel_registerName // call sel_registerName("CGContext"), result is in x0
    mov x1, x0 // move selector for CGContext into x1
    mov x0, x19 // move currentContext into x0
    bl _objc_msgSend       // call function with args (x0 = currentContext, x1 = CGContext selector), result is in x0
    mov x19, x0                // x19 = CGContextRef

    mov x20, #0                // Index counter (0 to 1023)

    

draw_loop:
    adrp x21, zpGridArray@PAGE 
    add  x21, x21, zpGridArray@PAGEOFF 
    ldrb w22, [x21, x20]       // Load byte (1 = painted, 0 = empty)
    
    cbz  w22, next_iteration   // If 0, skip drawing this cell

    // Convert 1D index to 2D coordinates
    mov  w23, #32 
    udiv w24, w20, w23          // w24 = y (row)
    msub w25, w24, w23, w20     // w25 = x (column)
  
    // set fill color for this cell from color array
    lsl  x9, x20, #5           // index * 32 (size of 4 doubles)
    adrp x8, zpGridColorArray@PAGE 
    add  x8, x8, zpGridColorArray@PAGEOFF
    add  x8, x8, x9

    mov  x0, x19               // Argument 0: CGContext
    ldp  d0, d1, [x8]          // R, G
    ldp  d2, d3, [x8, #16]     // B, A
    bl   _CGContextSetRGBFillColor // call function with args (x0 = CGContext, d0 = R, d1 = G, d2 = B, d3 = A), void

    // Define the 10x10 Rectangle
    scvtf d0, w25              // grid x = (int) x
    scvtf d1, w24              // grid y = (int) y
    fmov  d4, #10.0         // move floating point value 10.0into d4
    fmul  d0, d0, d4           // convert grid x to pixel x
    fmul  d1, d1, d4           // convert grid y to pixel y

    scvtf d5, x26              // load center offset
    fadd  d0, d0, d5           // apply offset to d0

    fmov  d2, #10.0            // pixel width = 10.0
    fmov  d3, #10.0            // pixel height = 10.0

    mov  x0, x19               // move CGContext into x0 for argument
    bl _CGContextFillRect      // call to function with args (x0 = CGContext, d0 = x, d1 = y, d2 = width, d3 = height), void

 
   
next_iteration:
    add  x20, x20, #1 // add 1 to x20
    cmp  x20, #1024  // compare x20 with 1024 (total number of cells)
    b.ne draw_loop  // check if x20 is not equal to 1024, if not, branch back to start of loop

    mov x0, x19        // CGContext

zpLoopDrawColorPalette:
    // x0 = CGContext*
    cbz x19, zpPaletteDone
    // --- DRAW COLOR PALETTE (Right-Hand Side) ---
    
    // 1. Get Window Dimensions ONCE before starting the loop
    adrp x7, zpWindowExtents@PAGE
    add  x7, x7, zpWindowExtents@PAGEOFF
    ldp  d12, d13, [x7, #16]   // d12 = width, d13 = height

    fcvtzs x27, d12            // x27 = Total Window Width (Stable)
    fcvtzs x28, d13            // x28 = Total Window Height (Stable)

    mov x20, #0                // Reset counter (i = 0 to 11)

zpPaletteLoop:
    cmp x20, #12
    b.ge zpPaletteDone         

    // 2. Layout Logic (Rows/Cols)
    mov x9, #2
    udiv x21, x20, x9          // x21 = row
    msub x22, x21, x9, x20     // x22 = col

    // 3. Compute Positions into CALLEE-SAVED registers (x25, x26)
    // These will survive the 'bl' call to SetRGBFillColor
    sub x10, x27, #100         // Base X
    lsr x11, x28, #1           
    sub x11, x11, #200         // Base Y center (adjusted from 500 to fit screen)

    mov x12, #40             // Spacing
    
    mul x14, x22, x12
    add x25, x10, x14          // Final X -> stored in x25 (Stable)
    
    mul x15, x21, x12          
    add x26, x11, x15          // Final Y -> stored in x26 (Stable)

    // 4. Load RGBA
    adrp x8, zpColorPalette@PAGE
    add  x8, x8, zpColorPalette@PAGEOFF
    lsl  x9, x20, #5           
    add  x8, x8, x9
    ldp  d0, d1, [x8]          
    ldp  d2, d3, [x8, #16]     

    // 5. Set Fill Color
    mov  x0, x19               
    bl   _CGContextSetRGBFillColor // x2, x3 etc. are likely destroyed here

    // 6. Draw Rect
    // We move our STABLE coordinates from x25/x26 into the float registers
    scvtf d0, x25               
    scvtf d1, x26               
    fmov  d2, #31.0            
    fmov  d3, #31.0            
    mov   x0, x19
    bl    _CGContextFillRect

    // 7. Increment and Loop
    add x20, x20, #1
    b zpPaletteLoop

zpPaletteDone:
    // Restore state: 80 bytes, reverse order of the prologue
    ldp x25, x26, [sp, #64]
    ldp x23, x24, [sp, #48]
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    
    // Restore Frame Pointer, Link Register, and deallocate stack space
    ldp x29, x30, [sp], #80
    
    ret


// Draw pixel at mouse position
zpDrawPixelAtMouse:
    adrp   x8, zpWindowPosition@PAGE
    add    x8, x8, zpWindowPosition@PAGEOFF
    ldr    d0, [x8]        // load saved mouse X from x8 address into d0
    ldr    d1, [x8, #8]    // load saved mouse Y from x8+8 address into d1



    fcvtzs w2, d0          // w2 = (int)x
    fcvtzs w3, d1          // w3 = (int)y

    //check if within bounds (0 to 319 for x, 0 to 319 for y)
    adrp   x8, zpGridSize@PAGE
    ldr    w4, [x8, zpGridSize@PAGEOFF] // load grid size (32) into w4 for comparison

    adrp x9, zpCellPixelSize@PAGE
    ldr w5, [x9, zpCellPixelSize@PAGEOFF] // load cell pixel size (10) into w5

    mul   w4, w4, w5     // w4 = grid size in pixels (320)
    sub w4, w4, #1     // w4 = 319 (max pixel index)

    cmp    w2, #0 // compare x with 0
    blt    handler_exit // if x < 0, exit handler
    cmp    w3, #0 // compare y with 0
    blt    handler_exit // if y < 0, exit handler
    cmp    w2, w4 // compare x with max pixel index
    bgt    handler_exit // check if y is greater than max pixel index
    cmp    w3, w4 // compare y with max pixel index
    bgt    handler_exit // check if y is greater than max pixel index


    mov    w4, #10    // w4 = cell pixel size (10)
    udiv   w2, w2, w4      // w2 = w2 / w4
    udiv   w3, w3, w4      // w3 = w3 / w4

    // calculate 1D Offset: index = (y * 32) + x
    mov    w5, #32 // w5 = grid width in cells
    madd   w6, w3, w5, w2  // w6 = (w3 * 32) + w2

    adrp   x8, zpCurrentTool@PAGE
    ldr    w9, [x8, zpCurrentTool@PAGEOFF]

    
    cmp    w9, #0 // compare current tool with 0 (pen)
    mov    w8, #1 // pen value
    mov    w10, #0   // eraser value
    csel   w8, w8, w10, eq // if current tool is pen (w9 == 0), w8 = 1, else w8 = 0 for eraser

    // ... after calculating 1D index in w6 ...

    // Mark pixel as "on" (1) or "off" (0)
    adrp   x7, zpGridArray@PAGE
    add    x7, x7, zpGridArray@PAGEOFF
    strb   w8, [x7, x6]         // Store 1 or 0

    // Now copy the 4 color doubles to the Color Array
    lsl    x9, x6, #5           // index * 32 (shift left by 5 is * 32)
    adrp   x7, zpGridColorArray@PAGE
    add    x7, x7, zpGridColorArray@PAGEOFF
    add    x7, x7, x9           // Target address in color array

    adrp   x10, zpCurrentColor@PAGE
    add    x10, x10, zpCurrentColor@PAGEOFF 

    ldp    d0, d1, [x10]        // Load R and G from current color
    ldp    d2, d3, [x10, #16]   // Load B and A from current color
    
    stp    d0, d1, [x7]         // Save R and G to grid color array
    stp    d2, d3, [x7, #16]    // Save B and A to grid color array

    ret

// load frame size into zpWindowExtents global variable for use in event handler and rendering function
zpGetWindowFrame:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]       // Save x19 to preserve our View pointer

    mov x19, x0             // Save the View pointer (passed in x0) to x19

    // 1. Get the selector for "frame"
    adrp x0, s_frame@PAGE
    add  x0, x0, s_frame@PAGEOFF
    bl _sel_registerName    // Returns selector in x0
    
    // 2. Prepare for msgSend
    mov x1, x0              // x1 = selector ("frame")
    mov x0, x19             // x0 = the View pointer
    
    bl _objc_msgSend        // Returns CGRect in d0, d1, d2, d3

    // 3. Store result in global variables
    adrp x8, zpWindowExtents@PAGE
    add  x8, x8, zpWindowExtents@PAGEOFF
    stp  d0, d1, [x8]        // Store origin.x, origin.y
    stp  d2, d3, [x8, #16]    // Store width, height

    ldr x19, [sp, #16]       // Restore x19
    ldp x29, x30, [sp], #32
    ret

// main function loop for setting up NSApplication, NSWindow, NSView, NSMenu and event handlers
_main:
    stp x29, x30, [sp, #-160]! // allocate stack space for 2 registers and 7 pairs of callee-saved registers, and align to 16 bytes
    mov x29, sp // save frame pointer

    // save callee-saved registers we will use
    stp x19, x20, [sp, #16] 
    stp x21, x22, [sp, #32]
    stp x23, x24, [sp, #48]
    stp x25, x26, [sp, #64]
    stp x27, x28, [sp, #80]

    // init app

    adrp x0, cls_NSApp@PAGE // load 4kb page address of "NSApplication"
    add  x0, x0, cls_NSApp@PAGEOFF // add page offset to get actual address of string
    bl _objc_getClass // call function with args (x0 = NSApplication string), result is in x0
    mov x19, x0        // move the nsApp into x19

    adrp x0, s_sharedApp@PAGE // load 4kb page address of "sharedApplication"
    add  x0, x0, s_sharedApp@PAGEOFF // add page offset to get actual address of string
    bl _sel_registerName // call sel_registerName("sharedApplication"), result is in x0
    mov x1, x0 // load selector for sharedApplication into x1
    mov x0, x19 // load selected NSApplication class into x0
    bl _objc_msgSend // call function with args (x0 = NSApplication class, x1 = sharedApplication selector), result is in x0
    mov x19, x0       // move shader nsapp instance into x19   

    // set activation policy
    adrp x0, s_setPol@PAGE // load 4kb page address of "setActivationPolicy:"
    add  x0, x0, s_setPol@PAGEOFF // add page offset to get actual address of string
    bl _sel_registerName // call sel_registerName("setActivationPolicy:"), result is in x0
    mov x1, x0 // load selector for setActivationPolicy: into x1
    mov x0, x19 // load nsapp instance into x0
    mov x2, #0 // load x2 with 0 for NSApplicationActivationPolicyRegular
    bl _objc_msgSend // call function with args (x0 = nsapp instance, x1 = setActivationPolicy: selector, x2 = 0 for regular), no result to save

    // selectors
    adrp x0, s_alloc@PAGE
    add  x0, x0, s_alloc@PAGEOFF
    bl _sel_registerName // allocate selector for "alloc"
    mov x20, x0 // move alloc selector into x20

    adrp x0, s_init@PAGE 
    add  x0, x0, s_init@PAGEOFF
    bl _sel_registerName // allocate selector for "init"
    mov x21, x0 // move init selector into x21

    adrp x0, s_utf8@PAGE
    add  x0, x0, s_utf8@PAGEOFF
    bl _sel_registerName // allocate selector for "stringWithUTF8String:"
    mov x22, x0 // move stringWithUTF8String: selector into x22

    adrp x0, cls_NSString@PAGE
    add  x0, x0, cls_NSString@PAGEOFF
    bl _objc_getClass // get NSString class, result is in x0
    mov x23, x0 // move NSString class into x23

    // Menu setup
    adrp x0, cls_NSMenu@PAGE
    add  x0, x0, cls_NSMenu@PAGEOFF
    bl _objc_getClass // get NSMenu class, call function with args (x0 = NSMenu class), result is in x0
    mov x1, x20 // move alloc selector into x1
    bl _objc_msgSend // call function with args (x0 = NSMenu class, x1 = alloc selector), result is in x0
    mov x1, x21 // move init selector into x1
    bl _objc_msgSend // call function with args (x0 = allocated NSMenu instance, x1 = init selector), result is in x0
    mov x24, x0 // move initialized NSMenu instance into x24

    adrp x0, cls_NSMenu@PAGE
    add  x0, x0, cls_NSMenu@PAGEOFF
    bl _objc_getClass // get NSMenu class, result is in x0
    mov x1, x20 // move alloc selector into x1
    bl _objc_msgSend // call function with args (x0 = NSMenu class, x1 = alloc selector), result is in x0
    mov x1, x21 // move init selector into x1
    bl _objc_msgSend // call function with args (x0 = allocated NSMenu instance, x1 = init selector), result is in x0
    mov x25, x0 // move initialized NSMenu instance into x25

    mov x0, x23 // move NSString class into x0
    mov x1, x22 // move stringWithUTF8String: selector into x1
    adrp x2, t_quit@PAGE
    add  x2, x2, t_quit@PAGEOFF
    bl _objc_msgSend // call function with args (x0 = NSString class, x1 = stringWithUTF8String: selector, x2 = "Quit" string), result is in x0
    mov x26, x0 // move "Quit" NSString instance into x26

    mov x0, x23 // move NSString class into x0
    mov x1, x22 // move stringWithUTF8String: selector into x1
    adrp x2, k_quit@PAGE
    add  x2, x2, k_quit@PAGEOFF
    bl _objc_msgSend // call function with args (x0 = NSString class, x1 = stringWithUTF8String: selector, x2 = "q" string), result is in x0
    mov x27, x0 // move "q" NSString instance into x27

    adrp x0, s_terminate@PAGE
    add  x0, x0, s_terminate@PAGEOFF
    bl _sel_registerName // call sel_registerName("terminate:"), result is in x0
    mov x28, x0 // move selector for terminate: into x28

    adrp x0, cls_NSMenuItem@PAGE
    add  x0, x0, cls_NSMenuItem@PAGEOFF
    bl _objc_getClass // get NSMenuItem class, result is in x0
    mov x1, x20 // move alloc selector into x1
    bl _objc_msgSend // call function with args (x0 = NSMenuItem class, x1 = alloc selector), result is in x0
    
    mov x23, x0 // move allocated NSMenuItem instance into x23
    adrp x0, s_initTitle@PAGE
    add  x0, x0, s_initTitle@PAGEOFF
    bl _sel_registerName // call sel_registerName("initWithTitle:action:keyEquivalent:"), result: "Quit" is in x0
    mov x1, x0 // move selector for initWithTitle:action:keyEquivalent: into x1
    mov x0, x23 // move allocated NSMenuItem instance into x0
    mov x2, x26 // move "Quit" NSString instance into x2 for title argument
    mov x3, x28 // move selector for terminate: into x3 for action argument
    mov x4, x27 // move "q" NSString instance into x4 for keyEquivalent argument
    bl _objc_msgSend // call function with args (x0 = allocated NSMenuItem instance, x1 = initWithTitle:action:keyEquivalent: selector, x2 = "Quit" NSString, x3 = terminate: selector, x4 = "q" NSString), result "NSMenuItem" is in x0
    mov x26, x0 // move initialized NSMenuItem instance into x26

    adrp x0, s_setTarget@PAGE
    add  x0, x0, s_setTarget@PAGEOFF
    bl _sel_registerName // call sel_registerName("setTarget:"), result is in x0
    mov x1, x0 // move selector for setTarget: into x1
    mov x0, x26 // move initialized NSMenuItem instance into x0
    mov x2, x19 // move nsapp instance into x2 for target argument
    bl _objc_msgSend // call function with args (x0 = initialized NSMenuItem instance, x1 = setTarget: selector, x2 = nsapp instance), void

    adrp x0, s_addItem@PAGE
    add  x0, x0, s_addItem@PAGEOFF
    bl _sel_registerName // call sel_registerName("addItem:"), result is in x0
    mov x1, x0 // move selector for addItem: into x1
    mov x0, x25 // move initialized NSMenu instance into x0
    mov x2, x26 // move initialized NSMenuItem instance into x2 for item argument
    bl _objc_msgSend // call function with args (x0 = initialized NSMenu instance, x1 = addItem: selector, x2 = initialized NSMenuItem instance), void

    adrp x0, cls_NSMenuItem@PAGE
    add  x0, x0, cls_NSMenuItem@PAGEOFF
    bl _objc_getClass // get NSMenuItem class, result is in x0
    mov x1, x20 // move alloc selector into x1
    bl _objc_msgSend // call function with args (x0 = NSMenuItem class, x1 = alloc selector), result is in x0
    mov x1, x21 // move init selector into x1
    bl _objc_msgSend // call function with args (x0 = allocated NSMenuItem instance, x1 = init selector), result is in x0
    mov x26, x0 // move initialized NSMenuItem instance into x26

    adrp x0, s_setSub@PAGE
    add  x0, x0, s_setSub@PAGEOFF
    bl _sel_registerName // call sel_registerName("setSubmenu:"), result is in x0
    mov x1, x0 // move selector for setSubmenu: into x1
    mov x0, x26 // move initialized NSMenuItem instance into x0
    mov x2, x25 // move initialized NSMenu instance into x2 for submenu argument
    bl _objc_msgSend // call function with args (x0 = initialized NSMenuItem instance, x1 = setSubmenu: selector, x2 = initialized NSMenu instance), void

    adrp x0, s_addItem@PAGE
    add  x0, x0, s_addItem@PAGEOFF
    bl _sel_registerName // call sel_registerName("addItem:"), result is in x0
    mov x1, x0 // move selector for addItem: into x1
    mov x0, x24 // move initialized NSMenu instance into x0
    mov x2, x26 // move initialized NSMenuItem instance into x2 for item argument
    bl _objc_msgSend // call function with args (x0 = initialized NSMenu instance, x1 = addItem: selector, x2 = initialized NSMenuItem instance), void

    adrp x0, s_setMenu@PAGE
    add  x0, x0, s_setMenu@PAGEOFF
    bl _sel_registerName // call sel_registerName("setMainMenu:"), result is in x0
    mov x1, x0 // move selector for setMainMenu: into x1
    mov x0, x19 // move nsapp instance into x0
    mov x2, x24 // move initialized NSMenu instance into x2 for menu argument
    bl _objc_msgSend // call function with args (x0 = nsapp instance, x1 = setMainMenu: selector, x2 = initialized NSMenu instance), void

    // Create custom view class
    adrp x0, cls_NSView@PAGE
    add  x0, x0, cls_NSView@PAGEOFF
    bl _objc_getClass // call function with args (x0 = NSView class), result is in x0
    adrp x1, zpBasicView@PAGE
    add  x1, x1, zpBasicView@PAGEOFF
    mov  x2, #0 // load x2 with 0 for no extra bytes for ivars
    bl _objc_allocateClassPair // call function with args (x0 = NSView class, x1 = "ZPBasicView" string, x2 = 0), result is in x0
    mov x28, x0  // move pointer to new ZPBasicView class into x28

    adrp x0, s_drawRect@PAGE
    add  x0, x0, s_drawRect@PAGEOFF
    bl _sel_registerName // call sel_registerName("drawRect:"), result is in x0
    mov x1, x0        // move selector for drawRect: into x1    

    adrp x2, zpCmdDrawRect@PAGE
    add  x2, x2, zpCmdDrawRect@PAGEOFF 

    adrp x3, zpDrawRectSignature@PAGE
    add  x3, x3, zpDrawRectSignature@PAGEOFF    


    mov x0, x28           // load pointer to ZPBasicView class into x0
    bl _class_addMethod // call function with args (x0 = ZPBasicView class, x1 = drawRect: selector, x2 = pointer to zpCmdDrawRect function, x3 = pointer to "v@:{CGRect={CGPoint=dd}{CGSize=dd}}" string), result is boolean success/failure which we ignore

    mov x0, x28
    bl _objc_registerClassPair // call function with args (x0 = ZPBasicView class), void


    // window setup
    adrp x0, cls_NSWindow@PAGE
    add  x0, x0, cls_NSWindow@PAGEOFF
    bl _objc_getClass // get NSWindow class, result is in x0
    mov x1, x20 // move alloc selector into x1
    bl _objc_msgSend // call function with args (x0 = NSWindow class, x1 = alloc selector), result is in x0
    mov x24, x0 // move allocated NSWindow instance into x24 for later use in initWithContentRect:styleMask:backing:defer:

    adrp x0, s_initRect@PAGE
    add  x0, x0, s_initRect@PAGEOFF
    bl _sel_registerName // call sel_registerName("initWithContentRect:styleMask:backing:defer:"), result is in x0
    mov x1, x0 // move selector for initWithContentRect:styleMask:backing:defer: into x1
    mov x0, x24 // move allocated NSWindow instance into x0
    adrp x8, zpWindowExtents@PAGE
    add  x8, x8, zpWindowExtents@PAGEOFF
    ldp  d0, d1, [x8] // load window origin x and y from zpWindowExtents into d0 and d1 (bottom left corner is 0,0 in Cocoa)
    ldp  d2, d3, [x8, #16] // load window width and height from zpWindowExtents into d2 and d3
    mov x2, #15 // load x2 with style mask for titled, closable, resizable window
    mov x3, #2 // load x3 with backing store type for buffered drawing
    mov x4, #0 // load x4 with boolean false for no deferred creation
    bl _objc_msgSend // call function with args (x0 = allocated NSWindow instance, x1 = initWithContentRect:styleMask:backing:defer: selector, x2 = style mask, x3 = backing store type, x4 = defer boolean), result is initialized NSWindow instance in x0
    mov x24, x0 // move initialized NSWindow instance into x24

    adrp x0, s_setTitle@PAGE
    add  x0, x0, s_setTitle@PAGEOFF
    bl _sel_registerName // call sel_registerName("setTitle:"), result is in x0
    mov x21, x0 // move selector for setTitle: into x21

    adrp x0, cls_NSString@PAGE
    add  x0, x0, cls_NSString@PAGEOFF
    bl _objc_getClass // get NSString class, result is in x0
    mov x1, x22 // move stringWithUTF8String: selector into x1
    adrp x2, zpWindowTitle@PAGE
    add  x2, x2, zpWindowTitle@PAGEOFF
    bl _objc_msgSend // call function with args (x0 = NSString class, x1 = stringWithUTF8String: selector, x2 = "ZPaint" string), result is in x0

    mov x2, x0 // move "ZPaint" NSString instance into x2 for title argument
    mov x0, x24 // move initialized NSWindow instance into x0
    mov x1, x21 // move selector for setTitle: into x1
    bl _objc_msgSend // call function with args (x0 = initialized NSWindow instance, x1 = setTitle: selector, x2 = "ZPaint" NSString), void

    adrp x0, s_makeKey@PAGE
    add  x0, x0, s_makeKey@PAGEOFF
    bl _sel_registerName // call sel_registerName("makeKeyAndOrderFront:"), result is in x0
    mov x1, x0 // move selector for makeKeyAndOrderFront: into x1
    mov x0, x24 // move initialized NSWindow instance into x0
    mov x2, #0 // load x2 with boolean false for no sender argument
    bl _objc_msgSend // call function with args (x0 = initialized NSWindow instance, x1 = makeKeyAndOrderFront: selector, x2 = false for sender), void




    // NSEvent monitor
    adrp x0, cls_NSEvent@PAGE
    add  x0, x0, cls_NSEvent@PAGEOFF
    bl _objc_getClass // get NSEvent class, result is in x0
    mov x25, x0 // move NSEvent class into x25

    adrp x0, s_addMon@PAGE
    add  x0, x0, s_addMon@PAGEOFF
    bl _sel_registerName // call sel_registerName("addLocalMonitorForEventsMatchingMask:handler:"), result is in x0
    mov x1, x0 // move the addLocalMonitorForEventsMatchingMask:handler into x1

    mov x0, x25 // move NSEvent class into x0
    mov x2, #66    // Mask for mouse dragging in x2
    adrp x3, zpEventBlockLiteralDrag@PAGE
    add  x3, x3, zpEventBlockLiteralDrag@PAGEOFF
    bl _objc_msgSend // Call function with args (x0 = NSEvent, x2 = #66), void

    // keydown monitor
    adrp x0, s_addMon@PAGE
    add  x0, x0, s_addMon@PAGEOFF
    bl _sel_registerName
    mov x1, x0           // Put the selector in x1

    mov x0, x25          // NSEvent class in x0
    mov x2, #0x400       // Mask (KeyDown) in x2
    adrp x3, zpEventBlockLiteralKeyDown@PAGE
    add  x3, x3, zpEventBlockLiteralKeyDown@PAGEOFF // Block in x3
    bl _objc_msgSend


    // instantiate custom view and set as content view
    mov x0, x28   // move pointer to ZPBasicView into x0
    mov x1, x20     // move alloc selector to x1
    bl _objc_msgSend   // call function with args (x0 = zpBasicView, x1 = alloc selector), result is in x0
    mov x25, x0     // move x0 into x25

    adrp x0, s_initWithFrame@PAGE
    add  x0, x0, s_initWithFrame@PAGEOFF
    bl _sel_registerName // call sel_registerName("initWithFrame:") result is in x0
    mov x1, x0      // move x0 into x1
    mov x0, x25     // move the zpBasicView Custom view instance into x0
    adrp x8, zpWindowExtents@PAGE
    add  x8, x8, zpWindowExtents@PAGEOFF
    ldp  d0, d1, [x8]    // load window rect x, y into d0, d1
    ldp  d2, d3, [x8, #16] // load window width, height into d2, d3
    bl _objc_msgSend            // call function to create the curtom view result in x0
    mov x25, x0                 // store result to x25

    adrp x8, zpViewPtr@PAGE
    add  x8, x8, zpViewPtr@PAGEOFF
    str x25, [x8] // store the x25 register into the view_ptr pointer at x8 memory address

    adrp x0, s_setCtxView@PAGE
    add  x0, x0, s_setCtxView@PAGEOFF
    bl _sel_registerName // call sel_registerName("setContentView:") to set current content view, result is in x0
    mov x1, x0  // move x0 into x1                
    mov x0, x24                 // move the initialized NSWindow instance into x0
    mov x2, x25                 // move the custom view into x2
    bl _objc_msgSend            // call function with args (x0 = NSWindow, x1 = NSCtxView, x2 = NSCustomView), void
    
    adrp x0, s_run@PAGE
    add  x0, x0, s_run@PAGEOFF
    bl _sel_registerName    // x0 now has the "run" selector
    mov x1, x0              // move "run" selector to x1
    
    mov x0, x19             // CRITICAL: Restore NSApplication instance to x0
    bl _objc_msgSend        // Now calling [NSApp run] instead of [NSView run]

    // load callee-saved registers and exit
    ldp x27, x28, [sp, #80]
    ldp x25, x26, [sp, #64]
    ldp x23, x24, [sp, #48]
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #160

    ret // return
