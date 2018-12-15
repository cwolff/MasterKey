Name            DISUTIL

Title           Master_key_display_utility

Subttl          Display_Message

Page 60,132

;**************************************************************************
;                                                                         *
;               (C)opyright 1983 Software Laboratories, Inc.              *
;                                                                         *
;                   Authors - Cameron L. Wolff                            *
;                                                                         *
;**************************************************************************

;
; File to be included with code for equates (EQUATES.INC)
;

                include c:mkdata.inc

;
; Public
;

                public display_message
                public display_menu
                public clear_window
                public clear_box
                public display_drives
                public display_date
                public side_display
                public yes_no

; Externals

                extrn  flush_key_board:near
                extrn  error_beep:near
                extrn  arrow_key:near
                extrn  yes_no_key:near

Subttl          Dispay_message

Page

Code_seg        segment public 'code'

; =========================================================================
; |                                                                       | 
; |                          DISPLAY MESSAGE                              |
; |                                                                       |
; |           Low level process for display to the screen                 |
; |               Displays message from right to left                     |
; |                                                                       |
; |           Entry:                                                      |
; |                    BL - color of message                              |
; |                 DS:CX - address of message                            |
; |                    DX - position of message                           | 
; |                         DH - line of screen                           |
; |                         DL - column of line                           |
; |                              if DL > 04fh then center message         |
; |                                                                       |
; =========================================================================

                assume cs:code_seg

Display_message proc    near

; Save incoming registers

                push    ax
                push    bx
                push    cx
                push    dx
                push    bp
                push    si
                push    ds
                push    es

                push    cs
                push    cs

                pop     ds
                pop     es

; Set up Display message and check limits

                mov     si,cx
                mov     al,[si]            ; al <- character count
                xor     ah,ah              ; clear garbage
                mov     bh,al
                dec     bh                 ; adjust for addition
                cmp     al,null_message    ; test for null message
                jbe     display_message_return
                cmp     dl,center_message  ; test for center
                jbe     message_positioned
                inc     bh                 ; readjust for centering
                shr     bh,1               ; length / 2
                mov     dl,center_column   ; center column (40)

         Message_positioned:

                add     dl,bh              ; set end of message column
                cmp     dl,column_limit    ; test screen limit (79 columns)
                jg      display_message_return
                cmp     dh,line_limit      ; test screen limit (24 lines)
                jg      display_message_return

        Display_loop:

                push    ax
                push    bx

                mov     ah,set_cursor
                mov     bh,page_0
                int     video_int

                pop     bx
                pop     ax

                push    ax
                push    bx
                push    si

                mov     bp,ax
                mov     al,ds:[si+bp]      ; get character
                mov     bh,page_0
                mov     cx,one_character
                mov     ah,display_screen
                int     video_int

                pop     si
                pop     bx
                pop     ax

                sub     dl,one_character   ; next column to the left
                sub     al,one_character   ; decrement message count
                jnz     display_loop

        Display_message_return:

                mov     ah,2
                mov     bh,0
                mov     dx,0ffffh
                int     10h

                pop     es
                pop     ds
                pop     si
                pop     bp
                pop     dx
                pop     cx
                pop     bx
                pop     ax

                ret

Display_message endp

Subttl         Side_display

Page

; ========================================================================
; |                                                                      |
; |                            SIDE DISPLAY                              |
; |                                                                      |
; |                     Display the data name from the                   |
; |                          global data area                            |
; |                                                                      |
; ========================================================================

Side_display    proc near

                push    ax
                push    bx
                push    cx
                push    dx
                push    ds
                push    es

                push    cs
                push    cs

                pop     ds
                pop     es

                cmp     head_number,0
                jne     display_side_1

                mov     bl,normal_video
                mov     cx,offset side_1_message
                mov     dx,side_1_position
                call    display_message

                mov     bl,reverse_video
                mov     cx,offset side_0_message
                mov     dx,side_0_position
                call    display_message

                jmp     side_display_return

        Display_side_1:

                mov     bl,normal_video
                mov     cx,offset side_0_message
                mov     dx,side_0_position
                call    display_message

                mov     bl,reverse_video
                mov     cx,offset side_1_message
                mov     dx,side_1_position
                call    display_message

        Side_display_return:

                pop     es
                pop     ds
                pop     dx
                pop     cx
                pop     bx
                pop     ax

                ret

Side_display    endp

Subttl         Display_data_drive

Page

; ========================================================================
; |                                                                      |
; |                             DISPLAY DRIVES                           |
; |                                                                      |
; |                  Display the data disk drive from the                |
; |                          global data area                            |
; |                                                                      |
; ========================================================================

Display_drives  proc near

                push    ax
                push    bx
                push    cx
                push    dx
                push    ds
                push    es

                push    cs
                push    cs

                pop     ds
                pop     es

; Display source drive message

                mov     ah,source_drive
                add     ah,'A'
                mov     source_drive_number_message,ah

                mov     cx,offset source_drive_message
                mov     dx,source_drive_position
                mov     bl,normal_video
                call    display_message

; Display target drive message

                mov     ah,target_drive
                add     ah,'A'
                mov     target_drive_number_message,ah

                mov     cx,offset target_drive_message
                mov     dx,target_drive_position
                mov     bl,normal_video
                call    display_message

; Display target drive

                pop     es
                pop     ds
                pop     dx
                pop     cx
                pop     bx
                pop     ax

                ret

Display_drives  endp

Subttl          Display_date

Page

; ------------------------------------------------------------------------
; |                                                                      |
; |                             DISPLAY DATE                             |
; |                                                                      |
; |                       Display the date to the menu                   |
; |                                                                      |
; ------------------------------------------------------------------------

Display_date    proc    near

                push    ax
                push    bx
                push    cx
                push    dx
                push    ds
                push    es

                push    cs
                push    cs

                pop     ds
                pop     es

; Get the date  ->  CX - year DH - month DL - day

                mov     ah,get_date
                int     dos_function_int

                push    cx                 ; save year

; Calculate month

                mov     bx,offset date_message+2 ; BX month rigtht digit
                mov     cx,2
                mov     al,dh              ; AL - month

        Month_loop:

                cbw
                div     modulos_10_byte    ; modulos 10 AH

                add     ah,'0'             ; convert to ascii
                mov     [bx],ah
                dec     bx                 ; BX month left digit

                loop    month_loop         ; month field done

                add     bx,3               ; BX points to '-'
                mov     ah,'-'
                mov     [bx],ah            ; put in delimeter

; Calculate day field

                add     bx,2               ; DS day right digit
                mov     cx,2
                mov     al,dl              ; AL day field

        Day_loop:

                cbw
                div     modulos_10_byte

                add     ah,'0'
                mov     [bx],ah
                dec     bx

                loop    day_loop           ; day field done

                add    bx,3
                mov    ah,'-'
                mov    [bx],ah             ; put in delimeter

; Calculate year field

                add    bx,4

                pop    cx                  ; restore year

                mov    ax,cx               ; AX - year
                mov    cx,4

      Year_loop:

                cwd
                div    modulos_10_word

                add    dl,'0'
                mov    [bx],dl
                dec    bx

                loop   year_loop           ; year field done

; Display date

                mov    cx,offset date_message
                mov    dx,date_position
                mov    bl,normal_video
                call   display_message

                pop    es
                pop    ds
                pop    dx
                pop    cx
                pop    bx
                pop    ax

                ret

Display_date    endp

Subttl          Clear_window

Page

; =========================================================================
; |                                                                       |
; |                            CLEAR WINDOW                               |
; |                                                                       |
; |                        CX - top row left column of coordinates        |
; |                        DX - bottome row right column of coordinates   |
; |                        BH - attribute of cleared window               |
; |                                                                       |
; =========================================================================

Clear_window    proc    near

                push    ax

                mov     ah,scroll_up
                mov     al,clear
                int     video_int

                pop     ax

                ret

Clear_window    endp

Subttl          Clear_small_box

Page

; =========================================================================
; |                                                                       |
; |                             CLEAR BOX                                 |
; |                                                                       |
; =========================================================================

Clear_box       proc    near

                push    bx
                push    cx
                push    dx

                mov     cx,0b03h
                mov     dx,154ch
                mov     bh,normal_video
                call    clear_window

                pop     dx
                pop     cx
                pop     bx

                ret

Clear_box       endp

Subttl          Yes_no

Page

; =========================================================================
; |                                                                       |
; |                               YES NO                                  |
; |                                                                       |
; |          Exit:                                                        |
; |                 CY - 0 if yes  CY - 1 if no                           |
; |                                                                       |
; =========================================================================

Yes_no          proc    near

                push    ax
                push    bx
                push    cx
                push    dx
                push    ds                 ; save callers DS
                push    es

                push    cs
                push    cs

                pop     ds
                pop     es

; Flush key board

                call    flush_key_board

; Clear status line

                mov     bh,normal_video
                mov     cx,1800h
                mov     dx,184fh
                call    clear_window

; Display yes no message and set up defaults

                stc

                pushf

                mov     bl,normal_video
                mov     cx,offset are_you_sure_message
                mov     dx,are_you_sure_position
                call    display_message

                mov     bl,normal_video
                mov     cx,offset yes_message
                mov     dx,yes_position
                call    display_message

                mov     bl,reverse_video
                mov     cx,offset no_message
                mov     dx,no_position
                call    display_message

        Read_yes_no:

                call    yes_no_key

                cmp     ah,return
                jne     toggle_yes_no

                jmp     yes_no_clean_up

        Toggle_yes_no:

                popf

                jc     set_yes_key

        Set_no_key:

                mov    bl,normal_video
                mov    cx,offset yes_message
                mov    dx,yes_position
                call   display_message

                mov    bl,reverse_video
                mov    cx,offset no_message
                mov    dx,no_position
                call   display_message

                stc

                pushf

                jmp    Read_yes_no

        Set_yes_key:

                mov    bl,reverse_video
                mov    cx,offset yes_message
                mov    dx,yes_position
                call   display_message

                mov    bl,normal_video
                mov    cx,offset no_message
                mov    dx,no_position
                call   display_message

                clc

                pushf

                jmp    Read_yes_no

        Yes_no_clean_up:

; Clear status line

                mov     cx,status_row
                mov     dx,bottom_home
                mov     bh,normal_video
                call    clear_window

; Check to see if the wish to esc

                popf
                pushf

                jnc     yes_no_return      ; esc no need to check status line

; Check to see if message needs to be display to status line

                cmp     status_message_pointer,0ffffh
                je      yes_no_return

                mov     bl,reverse_video
                mov     cx,status_message_pointer
                mov     dx,18ffh
                call    display_message

        Yes_no_return:

                popf

                pop     es
                pop     ds                 ; restore callers DS
                pop     dx
                pop     cx
                pop     bx
                pop     ax

                ret

Yes_no          endp

Subttl          Display_menu

Page

; =========================================================================
; |                                                                       |
; |                               DISPLAY MENU                            |
; |                                                                       |
; |                          Display function options.                    |
; |                            Low level menu driver.                     |
; |                               Clear screen.                           |
; |                                                                       |
; |            Entry:                                                     |
; |                     AX - number of function keys                      |
; |                  DS:BX - address of menu_message                      |
; |                     CX - box co-ordinates                             |
; |                          CH - height of box (row)                     |
; |                          CL - length of box (column)                  |
; |                     DX - position of upper left corner                |
; |                          DH - row                                     |
; |                          DL - column                                  |
; |                                                                       |
; |                  DS:BP - address of menu title                        |
; |                                                                       |
; =========================================================================

Display_menu            proc    near

; Save registers.

                push    ax
                push    bx
                push    cx
                push    dx
                push    bp
                push    si
                push    ds                 ; save callers DS
                push    es

                push    cs
                push    cs

                pop     ds
                pop     es

; Save box parametes for display box

                push    cx
                push    dx

; Clear screen.

                push    bx
                push    bp

                mov     bh,normal_video
                mov     cx,home
                mov     dx,bottom_home
                call    clear_window

                pop     bp
                pop     bx

; Display universal title lines.

                call    display_title

                mov     dh,al
                shr     dh,1
                add     dh,5

                push    dx

                mov     cx,bx

        Menu_display_loop:

                push    ax                 ; save number of function keys
                push    cx                 ; save address of message

                mov     bl,reverse_video
                add     al,ascii_convert
                mov     cx,offset function_key_message
                mov     si,cx
                mov     [si+2],al
                mov     dl,20              ; column 20
                call    display_message

                mov     bl,normal_video
                mov     dl,28              ; column 28
                mov     cx,offset arrow_message
                call    display_message    ; print <=====>

                pop     cx                 ; restore message address

                mov     dl,40              ; column 40
                call    display_message    ; display menu message

                pop     ax                 ; restore number of function keys

                sub     dh,1
                sub     al,1
                jz      esc_line

                mov     si,cx
                mov     ah,[si]            ; AH <-- length of message

                push    ax                 ; save number of function keys

                mov     al,ah
                xor     ah,ah
                add     cx,ax
                inc     cx                 ; point to start of next message

                pop     ax                 ; restore number of function keys

                jmp     menu_display_loop

        Esc_line:

                pop     dx

                add     dh,2                 ; skip line for esc display
                mov     dl,20              ; column 20
                mov     bl,reverse_video
                mov     cx,offset esc_message
                call    display_message

                mov     dl,40              ; column 40
                mov     bl,normal_video
                or      bl,08h             ; high intensity video
                mov     cx,offset exit_message
                call    display_message

; Print box

; Restore box parameters

                pop     dx
                pop     ax

                mov     bl,normal_video
                call    display_box

; Depress function key message

                mov     cx,offset depress_function_key_message
                shr     ah,1
                mov     dx,10ffh
                call    display_message

; Display date

                call    display_date

                mov     bl,normal_video
                mov     cx,offset version_message
                mov     dx,version_position
                call    display_message

                call    display_drives

                pop     es
                pop     ds                 ; restore callers DS
                pop     si
                pop     bp
                pop     dx
                pop     cx
                pop     bx
                pop     ax

                ret

Display_menu    endp

Subttl          Display_title

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                            DISPLAY TITLE                              |
; |                                                                       |
; |             Entry                                                     |
; |                  ES:BP - address of menu title                        |
; |                                                                       |
; -------------------------------------------------------------------------

Display_title   proc    near

                push    ax
                push    bx
                push    cx
                push    dx
                push    bp
                push    ds
                push    es

; Save menu title offset

                push    bp

; Display left frame of first row

                mov     bl,normal_video
;               or      bl,80h             ; blinking video
                mov     cx,offset left_frame_message
                mov     dh,0               ; first row of screen
                mov     dl,25
                call    display_message

; Display Master_key

                mov     bl,normal_video
                or      bl,08h             ; high intensity
                mov     cx,offset master_key_message
                mov     dh,0               ; first row of screen
                mov     dl,34
                call    display_message
    
; Display right frame of first row
    
                mov     bl,normal_video
;               or      bl,80h             ; blinking video
                mov     cx,offset right_frame_message
                mov     dh,0               ; first row of screen
                mov     dl,48
                call    display_message

; Display second line of title
    
                pop     bp

                mov     bl,reverse_video
                mov     cx,bp
                mov     dh,1               ; second row of screen
                mov     dl,2
                call    display_message

                pop     es
                pop     ds
                pop     bp
                pop     dx
                pop     cx
                pop     bx
                pop     ax

                ret

Display_title   endp

Subttl          Display_box

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                                DISPLAY BOX                            |
; |                                                                       |
; |                 Low level process to print box on screen.             |
; |                                                                       |
; |                    AH - height of box (row)                           |
; |                    AL - length of box (column)                        |
; |                    BL - color of box                                  |
; |                    DX - position of upper left corner                 | 
; |                         > 18h in DH (row) then center box             |
; |                         > 4fh in DL (column) then center box          |
; |                                                                       |
; -------------------------------------------------------------------------

Display_box     proc    near

; Save incoming registers.

                push    ax
                push    bx
                push    cx
                push    dx
                push    ds

; Set_up display box and test limits

                cmp     dh,line_limit      ; test to center line
                jbe     box_line_positioned
                mov     dh,ah
                shr     dh,1               ; heigth of box / 2
                add     dh,center_line     ; center line of box
                jmp     test_box_line

        Box_line_positioned:

                add     dh,ah              ; bottom line of box

        Test_box_line:

                cmp     dh,line_limit      ; test screen limits
                jbe     test_box_center
                jmp     display_box_return
 
        Test_box_center:

                cmp     dl,center_message  ; test to center column
                jbe     box_column_positioned
                mov     dl,al
                shr     dl,1               ; length of box / 2
                jmp     test_box_column

        Box_column_positioned:

                add     dl,al              ; right side of box

        Test_box_column:

                cmp     dl,column_limit    ; screen limits (79 columns)
                jbe     display_box_setup
                jmp     display_box_return

; DX has position of lower right corner
; Set DX to upper left corner

        Display_box_setup:

                sub     dh,ah
                sub     dl,al

; Test for valid length of box

                cmp     ah,smallest_box
                jae     display_first_row
                jmp     display_box_return

; Display first row of box

        Display_first_row:

                mov     si,offset bar_line_message
                mov     bp,ax
                and     bp,0ffh
                mov     [si],al
                mov     ch,upper_left_corner
                mov     [si+1],ch
                mov     ch,upper_right_corner
                mov     ds:[si+bp],ch
                mov     cx,si
                call    display_message

                sub     ah,one_row
                add     dh,one_row

                mov     si,offset space_line_message
                mov     bp,ax
                and     bp,0ffh
                mov     [si],al
                mov     ch,vertical_line
                mov     [si+1],ch
                mov     ds:[si+bp],ch
                mov     cx,si
                dec     ah

     Display_box_loop:

                call    display_message
                add     dh,one_row
                dec     ah
                jnz     display_box_loop

; Display last row of box

                mov     si,offset bar_line_message
                mov     bp,ax
                and     bp,0ffh
                mov     ch,lower_left_corner
                mov     [si+1],ch
                mov     ch,lower_right_corner
                mov     ds:[si+bp],ch
                mov     cx,si
                call    display_message

; Fix space_line_message & bar_line_message

                mov     si,offset bar_line_message
                mov     bp,ax
                and     bp,0ffh
                mov     ch,horizontal_line
                mov     [si+1],ch
                mov     ds:[si+bp],ch
                mov     si,offset space_line_message
                mov     bp,ax
                and     bp,0ffh
                mov     ch,blank
                mov     [si+1],ch
                mov     ds:[si+bp],ch

        Display_box_return:

                pop     ds
                pop     dx
                pop     cx
                pop     bx
                pop     ax

                ret

Display_box     endp

code_seg        ends

                end
p  d        pp  d        pp  c      