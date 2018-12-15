Name             MKCOPYU
 
Title            Master_key_copy_utility
 
Subttl           Copy_driver
 
Page 60,132
 
; *************************************************************************
; |                                                                       |
; |              (C)opyright 1982 1983 Software Laboratoties Inc.         |
; |                                                                       |
; |                  Author Cameron L. Wolff                              |
; |                                                                       |
; *************************************************************************
 
; Code segment
 
Code_seg        segment public 'code'
 
; Include

                include  c:mkdata.inc

; Public

                public   copy_driver
 
; Externals

                extrn start_copy_prompt:near,display_source_prompt:near
                extrn display_target_prompt:near,operation_display:near
                extrn disk_io_error:near,disk_map:near,display_message:near
                extrn sector_display:near,side_display:near,clear_window:near
                extrn display_current_track:near

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                           COPY DRIVER                                 |
; |                                                                       |
; |                  Handles copy disk function                           |
; |                                                                       |
; |        This utility copies many disks in either operating system      |
; |        (PC DOS OR CP/M-86) regardless of what operating system you    |
; |                          are running under.                           |
; |                                                                       |
; -------------------------------------------------------------------------

                assume cs:code_seg

Copy_driver     proc    near

; Prompt the user to insert disk(s)

                mov     track_number,0
                mov     old_track_number,0
                mov     verify_instruction,4

                mov     bx,offset read_write_parameter_block
                mov     read_write_parameter_pointer,bx
                mov     bx,offset format_parameter_block
                mov     format_parameter_pointer,bx

                mov     bx,offset read_instruction
                mov     read_instruction_pointer,bx
                mov     bx,offset write_instruction
                mov     write_instruction_pointer,bx
                mov     bx,offset verify_instruction
                mov     verify_instruction_pointer,bx

                call    start_copy_prompt

        Copy_loop:

                mov     ax,dta_seg
                mov     dta_seg_pointer,ax

                mov     al,number_of_tracks_to_read
                mov     track_counter,al

                mov     al,track_number

                push    ax
                push    read_write_parameter_pointer
                push    format_parameter_pointer
                push    write_instruction_pointer
                push    verify_instruction_pointer

                call    display_source_prompt

                call    source_driver

                mov     ax,dta_seg
                mov     dta_seg_pointer,ax

                mov     al,number_of_tracks_to_read
                mov     track_counter,al

                pop     verify_instruction_pointer
                pop     write_instruction_pointer
                pop     format_parameter_pointer
                pop     read_write_parameter_pointer
                pop     ax

                mov     track_number,al

                call    display_target_prompt

                call    target_driver

                cmp     track_number,40
                jb      copy_loop

        Copy_driver_exit:

                ret

Copy_driver     endp
 
Subttl          Copy

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                            SOURCE DRIVER                              |
; |                                                                       |
; |                   Maps and reads source diskette                      |
; |                                                                       |
; -------------------------------------------------------------------------

Source_driver   proc    near

                push    ds
                push    es

                push    cs
                push    cs

                pop     ds
                pop     es

; Disk copy loop

                mov     head_number,0

                call    display_current_track

        Disk_source_loop:

                call    side_display

                call    disk_map

                mov     bx,read_write_parameter_pointer

                cmp     byte ptr cs:[bx],0
                jne     read_disk

                mov    bl,normal_video
                mov    cx,offset map_not_formatted_message
                mov    dx,07ffh
                call   display_message

                xor    cx,cx

        Pause_loop:

                loop    pause_loop

                jmp     source_next_read

        Read_disk:

                call    disk_read

        Source_next_read:

                add     read_write_parameter_pointer,61
                add     format_parameter_pointer,62
                add     read_instruction_pointer,15
                add     write_instruction_pointer,15

                mov     bx,verify_instruction_pointer
                mov     al,cs:[bx]
                add     verify_instruction_pointer,15
                mov     bx,verify_instruction_pointer
                mov     cs:[bx],al

                cmp     head_number,0
                jne     source_next_track

                mov     head_number,1

                jmp     end_of_source_loop

        Source_next_track:

                inc     track_number

                dec     track_counter
                jz      source_driver_return

                mov     head_number,0

                call    display_current_track

        End_of_source_loop:

                jmp     disk_source_loop

        Source_driver_return:

                pop     es
                pop     ds

                ret

Source_driver   endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                           DESTINATION DRIVER                          |
; |                                                                       |
; |                 Formats writes and verifies destination disk          |
; |                                                                       |
; -------------------------------------------------------------------------

Target_driver   proc    near

                push    ds
                push    es

                mov     head_number,0

                call    display_current_track

        Disk_target_loop:

                call    side_display

                mov     bx,read_write_parameter_pointer

                cmp     byte ptr cs:[bx],0
                jne     format_disk

                call    unformat_track

                jmp     target_next_write

        Format_disk:

                call    disk_format

        Write_disk:

                call    disk_write

        Verify_disk:

                call    disk_verify

; Determine if copy done

        Target_next_write:

                add     read_write_parameter_pointer,61
                add     format_parameter_pointer,62
                add     write_instruction_pointer,15
                add     verify_instruction_pointer,15

                cmp     head_number,0
                jne     target_next_track

                mov     head_number,1

                jmp     end_of_target_loop

        Target_next_track:

                inc     track_number

                dec     track_counter
                jz      target_driver_return

                mov     head_number,0

                call    display_current_track

        End_of_target_loop:

                jmp     disk_target_loop

        Target_driver_return:

                pop     es
                pop     ds

                ret

Target_driver   endp

Subttl          Disk_read

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                             DISK READ                                 |
; |                                                                       |
; -------------------------------------------------------------------------

Disk_read       proc    near

                push    es

                mov     bx,format_parameter_pointer
                mov     al,cs:[bx]
                mov     end_of_track,al

                mov     bx,read_write_parameter_pointer
                mov     al,cs:[bx]
                mov     sector_counter,al
                inc     bx
                mov     parameter_pointer,bx

                mov     bx,read_instruction_pointer
                mov     read_instruction_ptr,bx

                mov     cx,offset read_message
                call    operation_display

        Disk_read_loop:

                mov     bx,parameter_pointer
                mov     al,[bx+2]          ; sector number
                call    sector_display

                mov     retry,3

        Disk_read_retry_loop:

                mov     bx,read_instruction_ptr
                mov     ah,cs:[bx]
                mov     al,1
                mov     ch,track_number

                mov     bx,parameter_pointer
                mov     cl,[bx+3]
                mov     bytes_per_sector,cl
                mov     cl,[bx+2]

                mov     dh,head_number
                mov     dl,source_drive

                mov     si,dta_seg_pointer
                mov     es,si

                mov     bx,0

                int     13h

                jnc     good_read

; Error on read operation do 3 retries

                push    ax

                mov     ah,0
                int     13h

                pop     ax

                cmp     ah,09h
                jne     error_on_read

        Dma_boundry_error_on_read:

                push    ax

                call    next_dta

                pop     ax

        Error_on_read:

                dec     retry
                jnz     disk_read_retry_loop

; 3 retries have failed inform the user

                call    disk_io_error

                jc      disk_read_loop     ; retry operation

        Good_read:

                call    next_dta

                inc     read_instruction_ptr

                dec     sector_counter
                jz      read_return

                add     parameter_pointer,4

                jmp     disk_read_loop

        Read_return:

                pop     es

                ret

Disk_read       endp

Subttl          Disk_format

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                            DISK FORMAT                                |
; |                                                                       |
; -------------------------------------------------------------------------

Disk_format     proc    near

                mov     bx,format_parameter_pointer
                mov     al,cs:[bx]
                mov     end_of_track,al

                mov     cx,offset format_message
                call    operation_display

        Disk_format_loop:

                mov     retry,3

        Disk_format_retry_loop:

                mov     ah,5

                mov     bx,format_parameter_pointer
                mov     al,cs:[bx]

                mov     ch,track_number

                inc     bx
                mov     cl,cs:[bx]
                mov     bytes_per_sector,cl

                inc     bx
                mov     cl,[bx+2]

                mov     dh,head_number
                mov     dl,target_drive

                int     13h

                jnc     format_return

; Error on read operation do 3 retries

                push    ax

                mov     ah,0
                int     13h

                pop     ax

        Error_on_format:

                dec     retry
                jnz     disk_format_retry_loop

; 3 retries have failed inform the user

                call    disk_io_error

                jc      disk_format_loop   ; retry operation

        Format_return:

                ret

Disk_format     endp

Subttl          Disk_write

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                             DISK WRITE                                |
; |                                                                       |
; -------------------------------------------------------------------------

Disk_write      proc    near

                push    es

                mov     bx,format_parameter_pointer
                mov     al,cs:[bx]
                mov     end_of_track,al

                mov     bx,read_write_parameter_pointer
                mov     al,cs:[bx]
                mov     sector_counter,al
                inc     bx
                mov     parameter_pointer,bx

                mov     bx,write_instruction_pointer
                mov     write_instruction_ptr,bx

                mov     cx,offset write_message
                call    operation_display

        Disk_write_loop:

                mov     bx,parameter_pointer
                mov     al,[bx+2]          ; sector number
                call    sector_display

                mov     retry,3

        Disk_write_retry_loop:

                mov     bx,write_instruction_ptr
                mov     ah,cs:[bx]
                mov     al,1
                mov     ch,track_number

                mov     bx,parameter_pointer
                mov     cl,[bx+3]
                mov     bytes_per_sector,cl
                mov     cl,[bx+2]

                mov     dh,head_number
                mov     dl,target_drive

                mov     si,dta_seg_pointer
                mov     es,si

                mov     bx,0

                int     13h

                jnc     good_write

; Error on write operation do 3 retries

                push    ax

                mov     ah,0
                int     13h

                pop     ax

                cmp     ah,09h
                jne     error_on_write

        Dma_boundry_error_on_write:

                push    ax

                call    next_dta

                pop     ax

        Error_on_write:

                dec     retry
                jnz     disk_write_retry_loop

; 3 retries have failed inform the user

                call    disk_io_error

                jc      disk_write_loop     ; retry operation

        Good_write:

                call    next_dta

                inc     write_instruction_ptr

                dec     sector_counter
                jz      write_return

                add     parameter_pointer,4

                jmp     disk_write_loop

        Write_return:

                pop     es

                ret

Disk_write      endp

Subttl          Disk_verify

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                             DISK VERIFY                               |
; |                                                                       |
; -------------------------------------------------------------------------

Disk_verify     proc    near

                mov     bx,format_parameter_pointer
                mov     al,cs:[bx]
                mov     end_of_track,al

                mov     bx,read_write_parameter_pointer
                mov     al,cs:[bx]
                mov     sector_counter,al
                inc     bx
                mov     parameter_pointer,bx

                mov     bx,verify_instruction_pointer
                mov     verify_instruction_ptr,bx

                mov     cx,offset verify_message
                call    operation_display

        Disk_verify_loop:

                mov     bx,parameter_pointer
                mov     al,[bx+2]          ; sector number
                call    sector_display

                mov     retry,3

        Disk_verify_retry_loop:

                mov     bx,verify_instruction_ptr
                mov     ah,cs:[bx]
                mov     al,1
                mov     ch,track_number

                mov     bx,parameter_pointer
                mov     cl,[bx+3]
                mov     bytes_per_sector,cl
                mov     cl,[bx+2]

                mov     dh,head_number
                mov     dl,target_drive

                mov     bx,0

                int     13h

                jnc     good_verify

; Error on read operation do 3 retries

                push    ax

                mov     ah,0
                int     13h

                pop     ax

                dec     retry
                jnz     disk_verify_retry_loop

; 3 retries have failed inform the user

                call    disk_io_error

                jc      disk_verify_loop     ; retry operation

        Good_verify:

                inc     verify_instruction_ptr

                dec     sector_counter
                jz      verify_return

                add     parameter_pointer,4

                jmp     disk_verify_loop

        Verify_return:

                ret

Disk_verify     endp

Subttl          Next_dta

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                             NEXT DTA                                  |
; |                                                                       |
; |                Set up the next DTA for disk access                    |
; |                                                                       |
; -------------------------------------------------------------------------

Next_dta        proc    near

                mov     bx,parameter_pointer
                mov     cl,[bx+3]
                mov     ax,sector_size
                cmp     cl,0
                je      no_shift_on_128

                shl     ax,cl              ; adjust for segment size

        No_shift_on_128:

                mov     cl,4
                shr     ax,cl              ; adjust for segment register

                mov     bx,dta_seg_pointer
                add     ax,bx
                mov     dta_seg_pointer,ax

                ret

Next_dta        endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                            UNFORMAT TRACK                             |
; |                                                                       |
; -------------------------------------------------------------------------

Unformat_track  proc    near

                mov     ah,bytes_per_sector
                mov     al,end_of_track

                push    ax

                mov     bytes_per_sector,6
                mov     end_of_track,1

                mov     cx,offset unformat_message
                call    operation_display
                
        Disk_unformat_loop:

                mov     retry,3

        Disk_unformat_retry_loop:

                mov     ah,5

                mov     al,1

                mov     ch,track_number
                mov     cl,1

                mov     dh,head_number
                mov     dl,target_drive

                int     13h

                jnc     unformat_return

; Error on read operation do 3 retries

                push    ax

                mov     ah,0
                int     13h

                pop     ax

        Error_on_unformat:

                dec     retry
                jnz     disk_unformat_retry_loop

; 3 retries have failed inform the user

                call    disk_io_error

                jc      disk_unformat_loop   ; retry operation

        Unformat_return:

                pop     ax

                mov     bytes_per_sector,ah
                mov     end_of_track,al

                ret

Unformat_track  endp

Code_seg        ends

                end_ftaka        rt

nomttak np

oesg    ns

        nfaa    t
ota p
eg  s
    a  
t 
g 
  a 
 g
   
 

prsco,h
        o   n                     