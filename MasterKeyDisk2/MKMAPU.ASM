Name            MKMAP

Title           Master_key

Subttl          Master_key_map

Page 60,132

; *************************************************************************
; |                                                                       |
; |             (C)opyright Software Laboratories Inc                     |
; |                                                                       |
; |                 Author - Cameron L. Wolff                             |
; |                                                                       |
; *************************************************************************

Code_seg        segment public 'code'

                assume cs:code_seg

; Include

                include c:mkdata.inc

; Publics

                public disk_map
                public validate_sector

; Externals


               extrn operation_display:near
               extrn sector_display:near
               extrn mk_look:near
               extrn disk_io_error:near
               extrn check_esc_key:near

Page

; =========================================================================
; |                                                                       |
; |                           DISK MAP                                    |
; |                                                                       |
; |                   Maps the source diskette in order                   |
; |                   to format the destination diskette                  |
; |                   in the same fashion.                                |
; |                                                                       |
; =========================================================================

Disk_map        proc    near

                push    ds
                push    es

                push    cs
                push    cs

                pop     ds
                pop     es

                cld

                mov     cx,offset map_message
                call    operation_display

; Read sector ID

        Read_id:

                call    mk_look

                mov     bx,read_write_parameter_pointer
                cmp     byte ptr cs:[bx],0
                je      disk_map_return

; Track formatted determine if track has mixed sectors

        Track_formatted:

; Flush out buffers

                mov     cx,15
                mov     di,offset verify_sector_block
                mov     al,0

                rep     stosb

                mov     cx,61
                mov     di,offset temporary_parameter_block
                mov     al,0

                rep     stosb

                call    format_blocks

        Disk_map_return:

                pop     es
                pop     ds

                ret

Disk_map        endp

Subttl          Format_blocks

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                           FORMAT BLOCKS                               |
; |                                                                       |
; -------------------------------------------------------------------------

Format_blocks   proc    near

                push    cs
                push    cs

                pop     ds
                pop     es

; Build validate parameter block

                call    validate_sector

; Set up format bytes per sector value

                mov     al,lowest_valid_sector
                mov     bx,format_parameter_pointer
                inc     bx
                mov     cs:[bx],al

; Build temporary parmaeter block

                push    cs
                push    cs

                pop     ds
                pop     es

                cld

                mov     bx,read_write_parameter_pointer
                mov     al,cs:[bx]
                mov     sector_counter,al
                mov     cl,2
                shl     al,cl
                mov     cl,al
                inc     cl
                xor     ch,ch
                mov     si,read_write_parameter_pointer
                mov     di,offset temporary_parameter_block

                cli

                rep     movsb

                sti

; Set up pointers and intialize block sizes

                mov     bx,read_write_parameter_pointer
                mov     al,0
                mov     [bx],al
                inc     bx
                mov     parameter_pointer,bx

                mov     bx,offset temporary_parameter_block
                inc     bx
                mov     temporary_pointer,bx

                mov     bx,offset verify_sector_block
                mov     verify_pointer,bx

                mov     bx,format_parameter_pointer
                mov     al,0
                mov     cs:[bx],al
                add     bx,2
                mov     format_pointer,bx

; Build format_parameter_block and read_write_parameter_block

        Parameter_build_loop:

                mov     bx,verify_pointer
                mov     al,[bx]
                test    al,80h
                jnz     just_build_format  ; sector does not verify

; Build read write block

                mov     di,parameter_pointer
                mov     si,temporary_pointer
                mov     cx,4

                cli

                rep     movsb

                sti

                mov     bx,read_write_parameter_pointer
                inc     byte ptr cs:[bx]
                add     parameter_pointer,4

; Build format block

                mov     di,format_pointer
                mov     si,temporary_pointer
                mov     cx,4

                cli

                rep     movsb

                sti

                mov     bx,format_parameter_pointer
                inc     byte ptr cs:[bx]
                add     format_pointer,4

; Check to see if size same as format size (determine if format needs pad)

                call    check_for_mixed_pad

                jmp     build_next_block

        Just_build_format:

                mov     di,format_pointer
                mov     si,temporary_pointer
                mov     cx,4

                cli

                rep     movsb

                sti

                mov     bx,format_parameter_pointer
                inc     byte ptr cs:[bx]
                add     format_pointer,4

        Build_next_block:

                dec     sector_counter
                jz      set_up_return

                add     temporary_pointer,4
                inc     verify_pointer

                jmp     parameter_build_loop

        Set_up_return:

                ret

Format_blocks   endp

Subttl          Validate_sector

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                             VALIDATE SECTOR                           |
; |                                                                       |
; -------------------------------------------------------------------------

Validate_sector proc    near

                mov     bx,read_write_parameter_pointer
                mov     al,cs:[bx]
                mov     sector_counter,al
                mov     end_of_track,al

                mov     bx,read_write_parameter_pointer
                inc     bx
                mov     parameter_pointer,bx
                mov     al,[bx+3]
                mov     lowest_valid_sector,al

                mov     bx,offset verify_sector_block
                mov     verify_pointer,bx

                mov     bx,read_instruction_pointer
                mov     read_instruction_ptr,bx
                mov     bx,write_instruction_pointer
                mov     write_instruction_ptr,bx
                mov     bx,verify_instruction_pointer
                mov     verify_instruction_ptr,bx

        Disk_validate_loop:

                mov     bx,parameter_pointer
                mov     al,[bx+2]
                call    sector_display

                mov     retry,3

                mov     second_retry,2

        Disk_validate_retry_loop:

                mov     bx,verify_instruction_ptr
                mov     ah,cs:[bx]
                mov     al,1
                mov     ch,track_number

                mov     bx,parameter_pointer
                mov     cl,[bx+3]
                mov     bytes_per_sector,cl
                mov     cl,[bx+2]

                mov     dh,head_number
                mov     dl,source_drive

                mov     bx,0

                int     13h

                jnc     good_validate

; Error on validate operation do 3 retries

                push    ax

                mov     ah,0
                int     13h

                pop     ax

                dec     retry
                jnz     disk_validate_retry_loop

; 3 retries have failed inform the user if not from unusual formatting

                cmp     ah,10h            ; CRC error in data field
                je      funny_formatting

                cmp     ah,04h
                jne     report_error

                dec     second_retry
                jz      report_error

                mov     bx,verify_instruction_ptr
                cmp     byte ptr cs:[bx],4
                je      normal_verify

                mov     byte ptr cs:[bx],04h
                jmp     end_of_verify_toggle

        Normal_verify:

                mov     byte ptr cs:[bx],0ah

        End_of_verify_toggle:

                mov     retry,3

                jmp     disk_validate_retry_loop

        Report_error:

                call    disk_io_error

                jnc     good_validate

                jmp     disk_validate_loop

        Funny_formatting:

                mov     si,verify_pointer
                mov     bx,parameter_pointer
                mov     al,[bx+3]
                or      al,80h
                mov     [si],al
                jmp     next_validate

        Good_validate:

                mov      si,verify_pointer
                mov      bx,parameter_pointer
                mov      al,[bx+3]
                and      al,7fh
                mov      [si],al
                cmp      al,lowest_valid_sector
                jae      next_validate
                mov      lowest_valid_sector,al

        Next_validate:

                mov      bx,verify_instruction_ptr
                cmp      byte ptr cs:[bx],4
                je       normal_read_write

                mov      byte ptr cs:[bx+1],0ah
                mov      bx,read_instruction_ptr
                mov      byte ptr cs:[bx],8
                inc      read_instruction_ptr
                mov      bx,write_instruction_ptr
                mov      byte ptr cs:[bx],9
                inc      write_instruction_ptr

                jmp      end_of_validate_loop

        Normal_read_write:

                mov      byte ptr cs:[bx+1],04h
                mov      bx,read_instruction_ptr
                mov      byte ptr cs:[bx],2
                inc      read_instruction_ptr
                mov      bx,write_instruction_ptr
                mov      byte ptr cs:[bx],3
                inc      write_instruction_ptr

        End_of_validate_loop:

                dec      sector_counter
                jz       validate_return

                inc      verify_pointer
                add      parameter_pointer,4

                inc      verify_instruction_ptr

                jmp      disk_validate_loop

        Validate_return:

                ret

Validate_sector endp

Subttl          Check_for_mixed_pad

; -------------------------------------------------------------------------
; |                                                                       |
; |                         CHECK FOR MIXED PAD                           |
; |                                                                       |
; -------------------------------------------------------------------------

Check_for_mixed_pad proc near

                mov     bx,temporary_pointer
                mov     al,[bx+3]
                cmp     al,lowest_valid_sector
                je      pad_format_return

; Format block needs to be padded determine how many sectors

                mov     cl,al
                sub     cl,lowest_valid_sector
                mov     al,1
                shl     al,cl              ; AL - number of sector to pad

; Check that its not zero

                cmp     al,0
                je      pad_format_return

                xor     ch,ch
                mov     cl,al
                dec     cl

; Check that it is not zero

                cmp     cl,0
                je      pad_format_return

; Never should be 8 or greater

                cmp     cl,8
                jae     pad_format_return

        Pad_block_loop:

                mov     bx,format_pointer
                mov     al,track_number
                mov     [bx],al
                mov     al,head_number
                mov     [bx+1],al
                mov     al,0ffh
                mov     [bx+2],al
                mov     al,lowest_valid_sector
                mov     [bx+3],al

                add     format_pointer,4
                mov     bx,format_parameter_pointer
                inc     byte ptr cs:[bx]

                loop    pad_block_loop

        Pad_format_return:

                ret

Check_for_mixed_pad endp

Code_seg        ends

                end
        n    n  n  ra_aaee_one        ic  bt t s[x        lo  pdboklo    Pdfra_eun        rt

hc_o_ie_a np

oesg    ns
e
                call    operation_display

        Disk_write_loop:

                mov     bx,para