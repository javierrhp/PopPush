SECTION "Entry point", ROM0[$150]

main::
   call gameng_init
   call gameng_run
   di     ;; Disable Interrupts
   halt   ;; Halt the CPU (stop procesing here)
