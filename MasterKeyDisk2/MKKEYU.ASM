Name            MKKEYU
 
Title           Master_key_key_util
 
Subttl          Read_Function_keys
 
Page 60,132

; *************************************************************************
; *                                                                       *
; *                (C)opyright 1983 Software Laboratories, Inc.           *
; *                    Authors - Bradley C. Davidson                      *
; *                              Cameron L. Wolff                         *
; *                                                                       *
; *************************************************************************

Code_seg        segment public 'code'

;
; File to be included with code for equates (EQUATES.INC)
;

                Include c:mkdata.inc

;
; Public
;

                public  function_key
                public  arrow_key
                public  return_key
                public  check_esc_key
                public  key_board
                public  kb_int
                public  error_beep
                public  flush_key_board
                public  yes_no_key

Subttl          Function_key

Page

; =========================================================================
; |                                                                       |
; |                            FUNCTION KEY                               |
; |                                                                       |
; |             Low level process for reading function key                |
; |                                                                       |
; |             ENTRY:                                                    |
; |                                                                       |
; |                      BX - Function key limits                         | 
; |                           BH - high function key                      |
; |                           BL - low function key                       |
; |                                                                       | 
; |             EXIT:                                                     |
; |                                                                       |
; |                      AH - Function key scan code                      |
; |                      AL - Ascii char code                             |
; |                                                                       |
; =========================================================================

                assume  cs:code_seg
 
Function_key    Proc    near

;
; Key board routine to read key from keybaord and determine if function key
;

                push    bx
                push    cx
                push    dx
                push    ds                 ; save callers DS

                push    cs
                pop     ds

; Flush key board first in case any stray keys

                call    check_esc_key

        Read_key_board:

                mov     ah,get_key
                int     key_board_int      ; get key

                cmp     ah,esc_scan_code   ; test esc key
                jne     test_function_key

                int     esc_key_int

                jmp     read_key_board     ; decided not to esc

        Test_function_key:

                cmp     ah,bh              ; test high limit
                ja      invalid_function_key

                cmp     ah,bl              ; test low limit
                jae     function_key_return

        Invalid_function_key:

                call    error_beep

                jmp     read_key_board

        Function_key_return:

                pop     ds                 ; restore callers DS
                pop     dx
                pop     cx
                pop     bx

                ret

Function_key    endp

Subttl          Arrow_key

Page

; =========================================================================
; |                                                                       |
; |                            ARROW KEY                                  |
; |                                                                       |
; |             Low level process for reading arrow keys                  |
; |                                                                       |
; |             EXIT:                                                     |
; |                                                                       |
; |                      AH - Function key scan code                      |
; |                      AL - 0                                           |
; |                                                                       |
; =========================================================================

Arrow_key       proc    near

;
; Key board routine to read key from keybaord and determine if arrow key
;

                push    bx
                push    cx
                push    dx
                push    ds                 ; save callers DS

                push    cs
                pop     ds

; Flush any stray keys

                call    check_esc_key

        Read_arrow_key:

                mov     ah,get_key
                int     key_board_int      ; get key

                cmp     ah,esc_scan_code   ; test esc key
                jne     test_arrow_key

                int     esc_key_int

                jmp     read_arrow_key     ; decided against esc

        Test_arrow_key:

                cmp     ah,left_arrow      ; test high limit
                je      arrow_key_return

                cmp     ah,right_arrow     ; test low limit
                je      arrow_key_return

                cmp     ah,up_arrow
                je      arrow_key_return

                cmp     ah,down_arrow
                je      arrow_key_return

                cmp     ah,return
                je      arrow_key_return

        Invalid_arrow_key:

                call    error_beep

                jmp     read_arrow_key

        Arrow_key_return:

                pop     ds                 ; restore callers DS
                pop     dx
                pop     cx
                pop     bx

                ret

Arrow_key       endp

Subttl          Return_key

Page

; =========================================================================
; |                                                                       |
; |                         RETURN KEY                                    |
; |                                                                       |
; =========================================================================

Return_key      proc    near

                push    ax

; Flush any stray keys

                call    check_esc_key

        Read_return_key:

                mov     ah,get_key
                int     key_board_int

                cmp     ah,esc_scan_code
                jne     check_for_return_key

                int     esc_key_int

                jmp     read_return_key

        Check_for_return_key:

                cmp     ah,return_scan_code   ; test esc key
                jne     read_return_error

                jmp     return_key_return

        Read_return_error:

                call    error_beep

                jmp     read_return_key

        Return_key_return:

                pop     ax

                ret

Return_key      endp

Subttl          Yes_no_key

Page

; =========================================================================
; |                                                                       |
; |                            YES NO KEY                                 |
; |                                                                       |
; |             Low level process for left right arrow keys & return      |
; |                                                                       |
; |             EXIT:                                                     |
; |                                                                       |
; |                      AH - Function key scan code                      |
; |                      AL - 0                                           |
; |                                                                       |
; =========================================================================

Yes_no_key      proc    near

;
; Key board routine to read key from keybaord and determine if arrow key
;

                push    bx
                push    cx
                push    dx
                push    ds                 ; save callers DS

                push    cs
                pop     ds

; Flush any stray keys

                call    flush_key_board

        Read_yes_no_keys:

                mov     ah,get_key
                int     key_board_int      ; get key

                cmp     ah,left_arrow
                je      yes_no_key_return

                cmp     ah,right_arrow
                je      yes_no_key_return

                cmp     ah,return
                je      arrow_key_return

        Invalid_yes_no_key:

                call    error_beep

                jmp     read_yes_no_keys

        Yes_no_key_return:

                pop     ds                 ; restore callers DS
                pop     dx
                pop     cx
                pop     bx

                ret

Yes_no_key      endp

Subttl          Check_esc_key

Page

; =========================================================================
; |                                                                       |
; |                         CHECK ESC KEY                                 |
; |                                                                       |
; =========================================================================

Check_esc_key   proc    near

                push    ax

        Read_esc_key:

                mov     ah,check_for_key
                int     key_board_int

                jz      check_esc_return

                mov     ah,get_key
                int     key_board_int

                cmp     ah,esc_scan_code   ; test esc key
                jne     read_esc_error

                int     esc_key_int

                jmp     check_esc_return

        Read_esc_error:

                call    error_beep

                jmp     read_esc_key

        Check_esc_return:

                pop     ax

                ret

Check_esc_key   endp

Subttl          Flush_key_board

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                           FLUSH KEY BOARD                             |
; |                                                                       |
; -------------------------------------------------------------------------

Flush_key_board proc    near

                push    ax

        Key_board_flush:

                mov     ah,check_for_key
                int     key_board_int

                jz      flush_return
                mov     ah,get_key
                int     key_board_int

                jmp     Key_board_flush

        Flush_return:

                pop     ax

                ret

Flush_key_board endp

Subttl         Key_board_io

Page

; $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
; $                                                                       $
; $                              KEY BOARD                                $
; $                                                                       $
; $         PROVIDES AN INTERFACE TO THE KEYBOARD FOR FILE CLERK II       $
; $                                                                       $
; $         Entry:                                                        $
; $                  AH - 0 read next ascii character in key board buffer $
; $         Exit:                                                         $
; $                  AL - 0 no need to return ascii character             $
; $                  AH - scan code                                       $
; $                                                                       $
; $         Entry:                                                        $
; $                  AH - 1 check to see if a character is available      $
; $         Exit:                                                         $
; $                  ZF - 0 character in buffer                           $
; $                  ZF - 1 buffer clear                                  $
; $                                                                       $
; $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

Key_board       proc    far

                sti

                push    ds
                push    bx
                push    ds
                push    es

                push    cs
                push    cs

                pop     es
                pop     ds

                or      ah,ah
                jz      ascii_read

                dec     ah
                jz      ascii_status

                jmp     key_board_return

        Ascii_read:

                sti

                nop                        ; while looping allow an interrupt

                cli

                mov     bx,buffer_head
                cmp     bx,buffer_tail
                jz      ascii_read

                mov     ax,[bx]
                call    increment_ptr

                mov     buffer_head,bx
                jmp     key_board_return

        Ascii_status:

                cli

                mov     bx,buffer_head
                cmp     bx,buffer_tail
                mov     ax,[bx]

                pop     es
                pop     ds
                pop     bx
                pop     ds

                ret     2                  ; needed to retain current flags

        Key_board_return:

                pop     es
                pop     ds
                pop     bx
                pop     ds

                iret                       ; return from interupt

Key_board       endp

Subttl          Increment_buffer_pointer

Page

; ------------------------------------------------------------------------
; |                                                                      |
; |                       INCREMENT BUFFER POINTER                       |
; |                                                                      |
; |                             Subroutine                               |
; |                                                                      |
; ------------------------------------------------------------------------

Increment_ptr   proc    near

                add     bx,2
                cmp     bx,offset kb_buffer_end
                jne     increment_ptr_ret
                mov     bx,offset kb_buffer

          Increment_ptr_ret:

                ret

Increment_ptr   endp

Subttl          Key_board_int

Page

; $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
; $                                                                       $
; $                          KEY INT                                      $
; $                                                                       $
; $                  Key board interrupt route                            $
; $                                                                       $
; $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

Kb_int         proc    near

                sti
 
                push    ax
                push    bx
                push    cx
                push    dx
                push    si
                push    di
                push    ds
                push    es

                cld                        ; string operation forward 

                push    cs
                push    cs

                pop     ds
                pop     es

                in      al,kb_data         ; read in the character
     
                push    ax                 ; save it

                in      al,kb_ctl          ; get the control port

                mov     ah,al              ; save value
                or      al,80h             ; reset bit for key board

                out     kb_ctl,al

                xchg    ah,al              ; get back original control

                out     kb_ctl,al          ; kb has been reset

                pop     ax                 ; recover scan code
                mov     ah,al              ; save scan code in AH also

; Test for overrun scan code for key board

                cmp     al,0ffh            ; is this an overrun character ?
                jnz     test_for_break_key

                call    error_beep         ; yes: generate a beep
                jmp     kb_int_ret

; Test for break key

        Test_for_break_key:

                 cmp    al,80h
                 jb     process_key

                 jmp    kb_int_ret

; Test for shift keys

        Process_key:

                mov     di,offset legal_characters
                xor     ch,ch
                mov     cl,[di]
                inc     di

                repne   scasb              ; look for a match

                mov     al,ah              ; recover scan code
                je      legal_character    ; match found

                call    error_beep

                jmp     kb_int_ret         ; return to user

; No need for ascii character place scan code and place in buffer

        Legal_character:

                mov     al,0               ; no ascii value

                mov     bx,buffer_tail     ; get the end pointer to buffer
                mov     si,bx              ; save the value
                call    increment_ptr      ; advance the tail
                cmp     bx,buffer_head     ; has the buffer wrapped around
                je      buffer_full        ; buffer full beep

                mov     [si],ax            ; store the value
                mov     buffer_tail,bx     ; move the pointer up

                jmp     kb_int_ret

        Buffer_full:

                call    error_beep

        Kb_int_ret:

                cli                        ; turn off interrupts

                mov     al,eoi             ; end of interrupt routine
                out     020h,al            ; interrupt return no EOI

                pop     es
                pop     ds
                pop     di
                pop     si
                pop     dx
                pop     cx
                pop     bx
                pop     ax                 ; restore state

                iret                       ; return, interrupts back on

Kb_int          endp

Subttl          Error_beep

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                            ERROR BEEP                                 |
; |                                                                       |
; -------------------------------------------------------------------------

Error_beep      proc    near

                push    ax
                push    bx
                push    cx
 
                mov     bx,050h

                in      al,kb_ctl

                push    ax

        Beep_cycle:

                and     al,0fch            ; turn off timer gate and speaker
                out     kb_ctl,al          ; output to control
                mov     cx,0d0h            ; half cycle time for tone

        Speaker_off:

                loop    speaker_off
 
                or      al,2
                out     kb_ctl,al
                mov     cx,0d0h            ; set up count

        Half_cycle:

                loop    half_cycle

                dec     bx                 ; total time count
                jnz     beep_cycle

                pop     ax
                out     kb_ctl,al
   
                pop     cx
                pop     bx
                pop     ax

                ret

Error_beep      endp

Code_seg        ends

                end      n          pp  a        ot  k_t,l
         pp  c        pp  b        pp  a        rt

ro_ep   np

oesg    ns

  restore message address

                mov     dl,40              ; column 40
                call    displa