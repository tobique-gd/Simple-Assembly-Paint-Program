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
zpWindowExtents:           .double 100.0, 100.0, 500.0, 500.0


zpEventBlockLiteral:
    .quad __NSConcreteGlobalBlock
    .int  0x10000000
    .int  0
    .quad zpBlockHandler
    .quad zpBlockDescriptor

zpBlockDescriptor:
    .quad 0
    .quad 32         

.text

.globl _main
.globl zpCmdDrawRect

.p2align 2
zpCmdDrawRect:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    stp x19, x20, [sp, #32]

    // NSGraphicsContext currentContext
    adrp x0, cls_NSGraphicsContext@PAGE
    add  x0, x0, cls_NSGraphicsContext@PAGEOFF
    bl _objc_getClass
    mov x19, x0

    adrp x0, s_currCtx@PAGE
    add  x0, x0, s_currCtx@PAGEOFF
    bl _sel_registerName
    mov x1, x0
    mov x0, x19
    bl _objc_msgSend
    mov x19, x0

    // CREATE CGContext
    adrp x0, s_CGContext@PAGE
    add  x0, x0, s_CGContext@PAGEOFF
    bl _sel_registerName
    mov x1, x0
    mov x0, x19
    bl _objc_msgSend
    mov x19, x0

    // SET FILL COLOR
    mov x0, x19 
    adrp x8, zpDrawnColor@PAGE 
    add  x8, x8, zpDrawnColor@PAGEOFF 
    ldp d0, d1, [x8] 
    ldp d2, d3, [x8, #16] 
    bl _CGContextSetRGBFillColor 

    // LOAD MOUSE POSITION
    adrp x8, zpWindowPosition@PAGE 
    add  x8, x8, zpWindowPosition@PAGEOFF
    ldr  d0, [x8]        
    ldr  d1, [x8, #8]    

    // LOAD SIZE ONLY from zpDrawnRect
    adrp x9, zpDrawnRect@PAGE 
    add  x9, x9, zpDrawnRect@PAGEOFF
    ldr  d2, [x9, #16]   
    ldr  d3, [x9, #24]   

    mov  x0, x19         
    bl _CGContextFillRect

    ldp x19, x20, [sp, #32] 
    ldp x29, x30, [sp], #48 
    ret

zpBlockHandler:
    stp x29, x30, [sp, #-64]! // allocate stack space for 2 registers and align to 16 bytes
    mov x29, sp  // save frame pointer
    stp x19, x20, [sp, #32] // save x19 and x20 for use in this function

    mov x19, x1    // x1 is the event object passed by the block literal which we pass into x19 for use in the function

    // Load mouse location selector
    adrp x0, zpEventsScreenMouseLocation@PAGE // load 4kb page address of "locationInWindow"
    add  x0, x0, zpEventsScreenMouseLocation@PAGEOFF // add page offset to get actual address of string
    bl _sel_registerName  // x0 now has the selector for "locationInWindow"
    mov x1, x0 // x1 is the selector for "locationInWindow"

    mov x0, x19 // load event object into x0 to call locationInWindow on it
    bl _objc_msgSend   // call [event locationInWindow], result is in x0

    // store mouse location in global position variable for use in drawRect
    adrp x8, zpWindowPosition@PAGE // load 4kb page address of zpWindowPosition
    add  x8, x8, zpWindowPosition@PAGEOFF // add page offset to get actual address of zpWindowPosition
    str d0, [x8] // store mouse x position in first double of zpWindowPosition
    str d1, [x8, #8] // store mouse y position in second double of zpWindowPosition

    // view redraw
    adrp x0, s_setNeedsDisplay@PAGE // load 4kb page address of "setNeedsDisplay:"
    add  x0, x0, s_setNeedsDisplay@PAGEOFF // add page offset to get actual address of string
    bl _sel_registerName // x0 now has the selector for "setNeedsDisplay:"
    mov x1, x0 // load selector for setNeedsDisplay: into x1

    adrp x8, zpViewPtr@PAGE // load 4kb page address of zpViewPtr
    add  x8, x8, zpViewPtr@PAGEOFF // add page offset to get actual address of zpViewPtr
    ldr  x0, [x8]   // load register pair x0 with the pointer to our custom view instance

    mov x2, #1   // load x2 with boolean true for setNeedsDisplay:
    bl _objc_msgSend // call [view setNeedsDisplay:true]

    mov x0, x19  // load event object into x0 to return it from the block handler
    ldp x19, x20, [sp, #32] // restore x19 and x20
    ldp x29, x30, [sp], #64 // restore x29 and x30, and adjust stack pointer back
    ret // return the event object as required by the block literal

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