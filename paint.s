.data

// external import strings
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

// Window methods
cls_NSWindow:   .asciz "NSWindow"

s_initTitle:    .asciz "initWithTitle:action:keyEquivalent:"
s_setTitle:     .asciz "setTitle:"

zpWindowTitle:          .asciz "ARMPaint"


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

.p2align 3
zpWindowPosition: .double 0.0, 0.0
zpViewPtr:        .quad 0
zpDrawnColor:     .double 0.3, 0.5, 0.1, 1.0
zpDrawnRect:      .double 0.0, 0.0, 100.0, 100.0
zpWindowExtents:           .double 100.0, 100.0, 320.0, 320.0

zpGridArray: .skip 1024  

zpGridSize:  .int 32
zpCellPixelSize: .int 10

zpCurrentTool: .int 0 // 0 = pen, 1 = eraser

.p2align 3
zpEventBlockLiteralKeyDown:
    .quad __NSConcreteGlobalBlock
    .int  0x10000000
    .int  0
    .quad zpBlockHandlerKeyDown
    .quad zpBlockDescriptor

.p2align 3
zpEventBlockLiteral:
    .quad __NSConcreteGlobalBlock
    .int  0x10000000
    .int  0
    .quad zpBlockHandler
    .quad zpBlockDescriptor

.p2align 3
zpBlockDescriptor:
    .quad 0
    .quad 32         
    .quad 0          // copy helper (not used)
    .quad 0          // dispose helper (not used)

.text

.globl _main
.globl zpCmdDrawRect

.p2align 2
set_pen:
    mov w21, #0
    b update_tool

.p2align 2
set_eraser:
    mov w21, #1
    b update_tool

.p2align 2
update_tool:
    adrp x8, zpCurrentTool@PAGE
    str  w21, [x8, zpCurrentTool@PAGEOFF]
    b handler_exit   // return to OS after updating tool

.p2align 2
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
    
    // 'b' is 98, 'e' is 101
    cmp w0, #98  
    b.eq set_pen
    cmp w0, #101     
    b.eq set_eraser
    b handler_exit

.p2align 2
handler_exit:
    mov x0, x19     
    ldp x21, x22, [sp, #48]
    ldp x19, x20, [sp, #32] 
    ldp x29, x30, [sp], #64
    ret

.p2align 2
zpCmdDrawRect:
    stp x29, x30, [sp, #-64]!
    mov x29, sp
    stp x19, x20, [sp, #32]
    stp x21, x22, [sp, #48]
    stp x23, x24, [sp, #16]

    // setup graphics context
    adrp x0, cls_NSGraphicsContext@PAGE
    add  x0, x0, cls_NSGraphicsContext@PAGEOFF
    bl _objc_getClass // call function with args (x0 = NSGraphicsContext class), result is in x0
    mov x19, x0        // move NSGraphicsContext class into x19      

    adrp x0, s_currCtx@PAGE
    add  x0, x0, s_currCtx@PAGEOFF
    bl _sel_registerName // call sel_registerName("currentContext"), result is in x0
    mov x1, x0             // move selector for currentContext into x1
    mov x0, x19            // move NSGraphicsContext class into x0
    bl _objc_msgSend       // call function with args (x0 = NSGraphicsContext class, x1 = currentContext selector), result is in x0
    mov x19, x0            // move current graphics context instance into x19

    adrp x0, s_CGContext@PAGE
    add  x0, x0, s_CGContext@PAGEOFF
    bl _sel_registerName // call sel_registerName("CGContext"), result is in x0
    mov x1, x0             // move selector for CGContext into x1
    mov x0, x19             // move current graphics context instance into x0
    bl _objc_msgSend       // call function with args (x0 = current graphics context instance, x1 = CGContext selector), result is in x0
    mov x19, x0            // x19 = CGContextRef

    mov x20, #0            // index counter

draw_loop:
    adrp x21, zpGridArray@PAGE
    add  x21, x21, zpGridArray@PAGEOFF
    ldrb w22, [x21, x20]   
    
    cbz  w22, next_iteration 

    mov  w23, #32 // grid width in cells
    udiv w24, w20, w23          // y
    msub w25, w24, w23, w20     // x

    mov x0, x19
    adrp x8, zpDrawnColor@PAGE 
    add  x8, x8, zpDrawnColor@PAGEOFF 
    ldp d0, d1, [x8] 
    ldp d2, d3, [x8, #16] 
    bl _CGContextSetRGBFillColor 

    scvtf d0, w25               
    scvtf d1, w24               
    fmov  d4, #10.0
    fmul  d0, d0, d4            
    fmul  d1, d1, d4            
    fmov  d2, #10.0             
    fmov  d3, #10.0             

    mov  x0, x19                
    bl _CGContextFillRect

next_iteration:
    add  x20, x20, #1
    cmp  x20, #1024
    b.ne draw_loop

    ldp x23, x24, [sp, #16]
    ldp x21, x22, [sp, #48]
    ldp x19, x20, [sp, #32]
    ldp x29, x30, [sp], #64
    ret

.p2align 2
zpBlockHandler:
    stp x29, x30, [sp, #-64]! 
    mov x29, sp
    stp x19, x20, [sp, #32] 

    mov x19, x1    

    // get mouse location in window
    adrp x0, zpEventsScreenMouseLocation@PAGE
    add  x0, x0, zpEventsScreenMouseLocation@PAGEOFF
    bl _sel_registerName
    mov x1, x0 
    mov x0, x19 
    bl _objc_msgSend   

    
    adrp x8, zpWindowPosition@PAGE
    add  x8, x8, zpWindowPosition@PAGEOFF
    str d0, [x8] // store mouse X in x8 address
    str d1, [x8, #8]  // store mouse Y in x8+8 address

    bl zpDrawPixelAtMouse  // write values to grid array based on mouse location and current tool


    // Trigger redraw
    adrp x0, s_setNeedsDisplay@PAGE
    add  x0, x0, s_setNeedsDisplay@PAGEOFF
    bl _sel_registerName
    mov x1, x0 

    mov x20, x1

    adrp x8, zpViewPtr@PAGE
    ldr  x0, [x8, zpViewPtr@PAGEOFF]
    mov  x1, x20                    // move selector for setNeedsDisplay: into x1
    mov  x2, #1                     // move boolean true into x2 for argument
    bl _objc_msgSend

    mov x0, x19  
    ldp x19, x20, [sp, #32] 
    ldp x29, x30, [sp], #64 
    ret

.p2align 2    
zpDrawPixelAtMouse:
    adrp   x8, zpWindowPosition@PAGE
    add    x8, x8, zpWindowPosition@PAGEOFF
    ldr    d0, [x8]        // load saved mouse X from x8 address into d0
    ldr    d1, [x8, #8]    // load saved mouse Y from x8+8 address into d1

    fcvtzs w2, d0          // w2 = (int)x
    fcvtzs w3, d1          // w3 = (int)y

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

    adrp   x7, zpGridArray@PAGE
    add    x7, x7, zpGridArray@PAGEOFF
    strb   w8, [x7, x6]     // write the value 1 or 0 into the grid array at the calculated index
    ret

.p2align 2
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
    adrp x3, zpEventBlockLiteral@PAGE
    add  x3, x3, zpEventBlockLiteral@PAGEOFF
    bl _objc_msgSend // Call function with args (x0 = NSEvent, x2 = #66), void
// --- Key Down Monitor ---
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
    bl _sel_registerName // call "run"
    mov x1, x0 // move result of run into x1
    mov x0, x19 // move nsApp instance into x0
    bl _objc_msgSend // call function with args (x0 = NSView, x1 = NSApplication), void

     // load callee-saved registers
    ldp x27, x28, [sp, #80]
    ldp x25, x26, [sp, #64]
    ldp x23, x24, [sp, #48]
    ldp x21, x22, [sp, #32]
    ldp x19, x20, [sp, #16]
    ldp x29, x30, [sp], #160

    ret // return