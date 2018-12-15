Name            MKMENU
 
Title           Master_key
 
Subttl          Initialize
 
Page 60,132

; *************************************************************************
; *                                                                       *
; *                (C)opyright 1983 Software Laboratories, Inc.           *
; *                                                                       *
; *                      Author  Cameron L. Wolff                         *
; *                                                                       *
; *************************************************************************

Code_seg       segment  public 'code'

               org      100h

;
; File to be included with code for equates (EQUATES.INC)
;

               include  c:mkdata.inc

;
; External routine calls
;

                extrn   key_board:near
                extrn   kb_int:near
                extrn   function_key:near
                extrn   arrow_key:near
                extrn   return_key:near
                extrn   display_menu:near
                extrn   display_message:near
                extrn   yes_no:near
                extrn   clear_box:near
                extrn   display_drives:near
                extrn   display_date:near
                extrn   clear_window:near
                extrn   copy_driver:near
 
                extrn   disk_driver:near
                extrn   disk_int:near

Page

; =========================================================================
; |                                                                       |
; |                          INITIALIZE                                   |
; |                                                                       |
; |       Initialize Global data table (Program Control Block)            |
; |       Registers DS and ES contain program prefix segment.             |
; |       Offset 0 of program prefix segment contains and INT 20          |
; |           which will return the user to DOS.                          |
; |                                                                       |
; =========================================================================

Mk_initialize   proc    far

                assume  cs:code_seg

; Initialize SP register

                 mov    sp,100h

; Set up DS and ES registers to CS

                push    cs
                push    cs

                pop     ds
                pop     es

; Set up interrupts for new keyboard routine

                push    es

                mov     ax,0
                mov     es,ax

                cli

                mov     bx,24h             ; key board int vector

                mov     ax,es:[bx]
                mov     keyint_offset,ax
                mov     ax,es:[bx+2]
                mov     keyint_segment,ax

                mov     ax,offset kb_int
                mov     es:[bx],ax
                mov     es:[bx+2],cs

                mov     bx,58h             ; key board I/O vetor

                mov     ax,es:[bx]
                mov     keyio_offset,ax
                mov     ax,es:[bx+2]
                mov     keyio_segment,ax

                mov     ax,offset key_board
                mov     es:[bx],ax
                mov     es:[bx+2],cs

                mov     bx,38h             ; disk int

                mov     ax,es:[bx]
                mov     old_disk_int_off,ax
                mov     ax,es:[bx+2]
                mov     old_disk_int_seg,ax

                mov     ax,offset disk_int
                mov     es:[bx],ax
                mov     es:[bx+2],cs

                mov     bx,4ch             ; disk i/o driver

                mov     ax,es:[bx]
                mov     old_disk_io_off,ax
                mov     ax,es:[bx+2]
                mov     old_disk_io_seg,ax

                mov     ax,offset disk_driver
                mov     es:[bx],ax
                mov     es:[bx+2],cs

                sti

                pop     es

; Turn off the cusor (move it off of the screen)

                mov     ah,2               ; set cursor position
                mov     bh,0
                mov     dx,0ffffh          ; turn off cursor
                int     video_int

; Get number of physical drives and set up default drives

                mov     ah,0
                int     11h

                and     ax,0c0h
                mov     cl,6
                shr     ax,cl
                or      al,al
                jz      one_drive

        Two_drives:

                mov     number_of_drives,2
                mov     source_drive,0
                mov     target_drive,1
                jmp     calculate_dta

        One_drive:

                mov     number_of_drives,1
                mov     source_drive,0
                mov     target_drive,0

; Enter main menu loop

        Calculate_dta:

                mov     ax,cs
                mov     bx,offset end_data
                mov     cl,4
                shr     bx,cl
                inc     bx
                add     ax,bx
                mov     dta_seg,ax

; Calculate the number of tracks that may be read in at once

                mov     cl,6

                shr     ax,cl
                inc     ax

                push    ax

                int     12h

                pop     bx

                sub     ax,bx

                cmp     ax,400
                jb      test_20_tracks

                mov     number_of_tracks_to_read,40
                jmp     int_end

        Test_20_tracks:

                cmp     ax,200
                jb      test_10_tracks

                mov     number_of_tracks_to_read,20
                jmp     int_end

        Test_10_tracks:

                cmp     ax,100
                jb      test_8_tracks

                mov     number_of_tracks_to_read,10
                jmp     int_end

        Test_8_tracks:

                cmp     ax,80
                jb      test_5_tracks

                mov     number_of_tracks_to_read,8
                jmp     int_end

        Test_5_tracks:

                cmp     ax,50
                jb      test_4_tracks

                mov     number_of_tracks_to_read,5
                jmp     int_end

        Test_4_tracks:

                cmp     ax,40
                jb      test_2_tracks

                mov     number_of_tracks_to_read,4
                jmp     int_end

        Test_2_tracks:

                cmp     ax,20
                jb      test_1_track

                mov     number_of_tracks_to_read,2
                jmp     int_end

        Test_1_track:

                cmp     ax,10
                jb      no_tracks

                mov     number_of_tracks_to_read,1
                jmp     int_end

        No_tracks:

                mov     number_of_tracks_to_read,0

        Int_end:

                jmp     mk_menu

; Program terminates to DOS from menu int.

Mk_initialize   endp
 
Subttl          Selection_menu

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                                MENU                                   |
; |                                                                       |
; |                    Main menu for Master Key                           |
; |         Set up return to dos. Clear screen and display menu.          |
; |                                                                       |
; -------------------------------------------------------------------------

Mk_menu         proc    near

; Initialize global data table (program control block)

               mov     main_menu_return_seg,cs
               mov     main_menu_return_off,offset main_menu_return_loop

; Display main menu

        Main_menu_return_loop:

                mov     ax,03              ; three function keys
                mov     bx,offset select_menu_message
                mov     bp,offset select_menu_title
                mov     cx,menu_box_parameters
                mov     dx,menu_box_position
                call    display_menu

; Display disk drive message

                jmp     get_function_key

        Secondary_menu_return_loop:

                call    clear_box

; Redisplay depress function key message (return from local menu functions)

                mov     cx,offset depress_function_key_message
                mov     dx,10ffh
                mov     bl,normal_video
                call    display_message

        Get_function_key:

; Initialize ESC key interrupt vector for dos return.
; Esc int. return entry point from lower level menus.

                push    es

                cli

                mov     ax,0h
                mov     es,ax

                mov     ax,offset dos_esc_int
                mov     es:[esc_key_addr],ax
                mov     es:[esc_key_addr+2],cs

                sti

                pop     es

; Ask for function key 1 to 8 only

                mov     status_message_pointer,0ffffh

                mov     bh,f3
                mov     bl,f1
                call    function_key

; Valid choice from user. Set up menu esc int. for return to main menu.
; Calls menu selected.

        Valid_master_menu_key:

                push    ax                 ; save function key
                push    es

                cli

                mov     ax,0h
                mov     es,ax

                mov     ax,offset menu_esc_int
                mov     es:[esc_key_addr],ax
                mov     es:[esc_key_addr+2],cs

                sti

                pop     es
                pop     ax                 ; restore function key

; Decide what function key was selected

                cmp     ah,f1
                jne     not_select_drives

                call    select_drives
                jmp     secondary_menu_return_loop

        Not_select_drives:

                cmp     ah,f2
                jne     not_start_copying

                call    copy_driver

                jmp     main_menu_return_loop

        Not_start_copying:

                call   mk_help

                jmp     secondary_menu_return_loop

Mk_menu         endp

Subttl          Dos_interrupt_handler

Page

; $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
; $                                                                       $
; $                  DOS ESC Interrupt HANDLER                            $
; $                                                                       $
; $          Handles the return to the operating system.                  $
; $                                                                       $
; $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

Dos_esc_int     proc    far

                sti

                call    yes_no

                jnc     dos

        Stay_at_menu:

                iret

        Dos:

                mov     cx,home
                mov     dx,bottom_home
                mov     bh,normal_video
                call    clear_window       ; clear screen

; Restore keyboard interrupt address

                push    cs
                pop     ds

                mov     ax,0
                mov     es,ax

                cli

                mov     bx,24h
                mov     ax,keyint_offset
                mov     es:[bx],ax
                mov     ax,keyint_segment
                mov     es:[bx+2],ax

                mov     bx,58h
                mov     ax,keyio_offset
                mov     es:[bx],ax
                mov     ax,keyio_segment
                mov     es:[bx+2],ax

                mov     bx,38h            ; disk int

                mov     ax,old_disk_int_off
                mov     es:[bx],ax
                mov     ax,old_disk_int_seg
                mov     es:[bx+2],ax

                mov     bx,4ch            ; disk i/o driver

                mov     ax,old_disk_io_off
                mov     es:[bx],ax
                mov     ax,old_disk_io_seg
                mov     es:[bx+2],ax

                sti

; Return to DOS

                int    20h

Dos_esc_int     endp

Subttl          Main_menu_interrupt_handler

Page

; $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
; $                                                                       $ 
; $                    MAIN MENU Interrupt HANDLER                        $
; $                                                                       $
; $            Handles the return to the main menu. Emergency             $
; $               exit from lower level menu processes.                   $
; $                                                                       $
; $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

Menu_esc_int    proc    far

                sti

                call    yes_no

                jnc     return_to_menu

        Dont_return_to_menu:

                 iret

        Return_to_menu:

; Reset the stack and place menu as return address (restore DS & ES for MENU)

                push    cs
                push    cs

                pop     ds
                pop     es

                mov     sp,100h             ; reset stack to top

                pushf                       ; put flag on stack for iret

                mov     ax,main_menu_return_seg
                push    ax
                mov     ax,main_menu_return_off
                push    ax

                iret                       ; returns to main menu

Menu_esc_int    endp

Subttl          Select_drives

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                          SELECT DRIVES                                |
; |                                                                       |
; -------------------------------------------------------------------------

Select_drives   proc   near

; Check if there are 2 Drives

                cmp    number_of_drives,2
                je     Selection_prompt

; Only 1 drive inform the user that they can not select drives

                mov    bl,reverse_video
                mov    cx,offset one_drive_message

                mov    status_message_pointer,cx

                mov    dx,one_drive_position
                call   display_message 

                call   return_key

                mov    status_message_pointer,0ffffh

                mov     bh,normal_video
                mov     cx,1800h
                mov     dx,184fh
                call    clear_window

                jmp    select_drives_return

; Display use key prompt

        Selection_prompt:

                call   clear_box

                mov    bl,normal_video
                mov    cx,offset use_key_message
                mov    dx,use_key_position
                call   display_message

                mov    bl,reverse_video
                mov    cx,offset select_source_drive_message
                mov    dx,select_source_drive_position
                call   display_message

                mov    bl,normal_video
                mov    cx,offset select_target_drive_message
                mov    dx,select_target_drive_position
                call   display_message

                call   display_drive_selection

                mov    bl,normal_video
                mov    cx,offset selection_complete_message
                mov    dx,selection_complete_position
                call   display_message

; Messages displayed now get users selection

                clc

        Get_user_drive_selection:

                pushf

                call   arrow_key

; Is this a return key

                cmp    ah,return
                jne    check_arrow

                popf
                jmp    select_drives_return

; Check to see if drives are to be changed

        Check_arrow:

                cmp    ah,left_arrow
                je     toggle_drive_selection

                cmp    ah,right_arrow
                je     toggle_drive_selection

                jmp    toggle_selection

; User enterd LEFT or RIGHT arrow decide wheter to toggle source or target

        Toggle_drive_selection:

                popf
                pushf

                jc     toggle_target_drives

                cmp    source_drive,0
                jne    set_source_to_zero

                mov    source_drive,1

                jmp    display_choice

        Set_source_to_zero:

                mov    source_drive,0

                jmp    display_choice

        Toggle_target_drives:

                cmp    target_drive,0
                jne    set_target_to_zero

                mov    target_drive,1

                jmp    display_choice

        Set_target_to_zero:

                mov    target_drive,0

        Display_choice:

                call    display_drive_selection

                popf

                jmp    get_user_drive_selection

; User entered UP or DOWN arror toggle select messages

        Toggle_selection:

                popf
                jnc    display_target_selection

; Display source drive selection

                mov    bl,reverse_video
                mov    cx,offset select_source_drive_message
                mov    dx,select_source_drive_position
                call   display_message

                mov    bl,normal_video
                mov    cx,offset select_target_drive_message
                mov    dx,select_target_drive_position
                call   display_message

                clc

                jmp    get_user_drive_selection
                
; Display taget drive selection

        Display_target_selection:

                mov    bl,normal_video
                mov    cx,offset select_source_drive_message
                mov    dx,select_source_drive_position
                call   display_message

                mov    bl,reverse_video
                mov    cx,offset select_target_drive_message
                mov    dx,select_target_drive_position
                call   display_message

                stc

                jmp    get_user_drive_selection

        Select_drives_return:

                ret

Select_drives   endp

Subttl          Display_drive_selection

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                          DISPLAY DRIVE SELECTION                      |
; |                                                                       |
; -------------------------------------------------------------------------

Display_drive_selection proc near

; Determine what source drive is to be displayed as reverse

        Need_to_toggle_source:

                cmp     source_drive,0
                jne     display_source_b_reverse

; Display source drive A: as reverse

                mov     bl,reverse_video
                mov     cx,offset drive_a_selection_message
                mov     dx,select_source_drive_position
                mov     dl,drive_a_column
                call    display_message

                mov     bl,normal_video
                mov     cx,offset drive_b_selection_message
                mov     dx,select_source_drive_position
                mov     dl,drive_b_column
                call    display_message

                jmp     need_to_display_target

; Display source drive B: as reverse

        Display_source_b_reverse:

                mov    bl,normal_video
                mov    cx,offset drive_a_selection_message
                mov    dx,select_source_drive_position
                mov    dl,drive_a_column
                call   display_message

                mov    bl,reverse_video
                mov    cx,offset drive_b_selection_message
                mov    dx,select_source_drive_position
                mov    dl,drive_b_column
                call   display_message

; Determine what target drive is to be display as reverse

        Need_to_display_target:

                cmp     target_drive,0
                jne     display_target_b_reverse

; Display target drive A: as reverse

                mov     bl,reverse_video
                mov     cx,offset drive_a_selection_message
                mov     dx,select_target_drive_position
                mov     dl,drive_a_column
                call    display_message

                mov     bl,normal_video
                mov     cx,offset drive_b_selection_message
                mov     dx,select_target_drive_position
                mov     dl,drive_b_column
                call    display_message

                jmp     display_drives_selected

; Display target drive B: as reverse

        Display_target_b_reverse:

                mov    bl,normal_video
                mov    cx,offset drive_a_selection_message
                mov    dx,select_target_drive_position
                mov    dl,drive_a_column
                call   display_message

                mov    bl,reverse_video
                mov    cx,offset drive_b_selection_message
                mov    dx,select_target_drive_position
                mov    dl,drive_b_column
                call   display_message

; Update Menu drive messages

        Display_drives_selected:

                call   display_drives

                ret

Display_drive_selection endp

Subttl          Mk_help

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                           MASTER KEY HELP                             |
; |                                                                       |
; -------------------------------------------------------------------------

Mk_help         proc    near

; Display status message

                mov     bl,reverse_video
                mov     cx,offset help_return_message

                mov     status_message_pointer,cx

                mov     dx,hold_on_position
                call    display_message

; Diplay text to user

                call    clear_box

                mov     bl,normal_video
                mov     cx,offset help_message
                mov     si,cx
                mov     dx,0cffh
 
        Help_display_loop:

                call    display_message

                mov     al,[si]
                xor     ah,ah
                add     cx,ax
                inc     cx
                mov     si,cx
                mov     al,[si]

; See if at end of page

                cmp     al,0ffh
                jne     check_for_end_of_help

                inc     cx
                mov     si,cx

                call    return_key

                mov     dx,0cffh
                jmp     help_display_loop

; See if at end of help

        Check_for_end_of_help:

                cmp     al,00
                jne     next_line

                call    return_key

                jmp     help_done

; Display next line of help message

        Next_line:

                inc     dh
                jmp     help_display_loop

; Clear box and status message and return

        Help_done:

                mov     status_message_pointer,0ffffh

                mov     bh,normal_video
                mov     cx,1800h
                mov     dx,184fh
                call    clear_window

                ret

Mk_help         endp
   
Code_seg        ends

                end    Mk_initialize
khl     np
 Cd_e    ed        ed  kiiilzh   p C_  e    e kilh pC e  eklhp  elp l    d,8f        cl  cerwno        rt

r      bl,08h             ; high intens