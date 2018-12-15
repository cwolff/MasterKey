Name            MKLOOK

Title           Master_key

Subttl          Master_key_Look

Page 60,132

; *************************************************************************
; |                                                                       |
; |             (C)opyright 1983 Software Laboratories Inc                |
; |                                                                       |
; |                 Author - Cameron L. Wolff                             |
; |                                                                       |
; *************************************************************************

Code_seg        segment public 'code'

                assume  cs:code_seg

;
; Include
;

                include c:mkdata.inc

;
; Extrn
;

                extrn  check_esc_key:near
                extrn  disk_io_error:near

;
; Public
;

                public  mk_look

Page

; =========================================================================
; |                                                                       |
; |                             MK LOOK                                   |
; |                                                                       |
; =========================================================================

Mk_look         proc    near

                push    ds
                push    es

                push    cs
                push    cs
                pop     es
                pop     ds

        Mk_look_error_loop:

                call    clear_buffers

                mov     retry,3

; Read the current track in order to position disk for

        Read_track:

                mov     ah,7
                mov     al,1
                mov     ch,track_number
                mov     cl,1
                mov     dh,head_number
                mov     dl,source_drive
                mov     bx,0
 
                int     13h

                jnc     read_id_loop

                push    ax

                mov     ax,0
                int     13h

                pop     ax

                cmp     ah,02h
                je      damaged_track_or_not_formated

                call    disk_io_error

                jnc     mk_look_return

                jmp     mk_look_error_loop

        Damaged_track_or_not_formated:

                jmp     mk_look_return

        Read_track_error:

                call    disk_io_error

                jmp     mk_look_error_loop

        Read_id_loop:

                mov     ah,6
                mov     al,1
                mov     ch,track_number
                mov     cl,1
                mov     dh,head_number
                mov     dl,source_drive
                mov     bx,0

                int     13h

                jnc     get_sector_id

                push    ax

                mov     ah,0
                int     13h

                pop     ax

                call    disk_io_error

                jnc     mk_look_return

                jmp     mk_look_error_loop

        Get_sector_id:

                push    ds

                mov     ax,40h
                mov     ds,ax

                inc     sector_count

                mov     cx,4
                mov     si,nec_status+3
                mov     di,sectors_on_track_pointer

                rep     movsb

                pop     ds

                mov     sectors_on_track_pointer,di

                cmp     sector_count,1
                je      first_pass        ; first time through dont check

                mov     al,sectors_on_track[2]
                cmp     es:[di-2],al
                je      read_all_sectors

        First_pass:

                jmp     read_id_loop

        Read_all_sectors:

                call    order_sectors

        Mk_look_return:

                pop     es
                pop     ds

                ret

Mk_look         endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                            CLEAR BUFFERS                              |
; |                                                                       |
; -------------------------------------------------------------------------

Clear_buffers   proc    near

                mov     sector_count,0

                mov     ax,offset sectors_on_track
                mov     sectors_on_track_pointer,ax

                mov     cx,69
                mov     di,offset sectors_on_track
                mov     al,0

                rep     stosb

                ret

Clear_buffers   endp

Page

; =========================================================================
; |                                                                       |
; |                             ORDER SECTORS                             |
; |                                                                       |
; =========================================================================

Order_sectors  proc     near

               xor      ax,ax

               dec      sector_count
               mov      al,sector_count

               mov      bx,read_write_parameter_pointer
               mov      cs:[bx],al

               mov      si,offset sectors_on_track
               mov      di,read_write_parameter_pointer
               add      di,5

               dec      ax
               jz       first_sector

               mov      cl,2
               shl      ax,cl
               mov      cx,ax

               rep      movsb

        First_sector:

               mov      cx,4
               mov      di,read_write_parameter_pointer
               add      di,1

               rep      movsb

               ret

Order_sectors  endp

Code_seg        ends

                end
,        o   d,edwieprmtrpitr
       a