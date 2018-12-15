Name            MKINT13

Title           Master_Key

Subttl          Interrupt_13

Page 60,132

; *************************************************************************
; *                                                                       *
; *               (C)opyright 1983 Software Laboratories Inc.             *
; *                                                                       *
; *                       Author  Cameron L. Wolff                        *
; *                                                                       *
; *************************************************************************

Code_seg        segment public 'code'

                assume cs:code_seg

;
; External
;

                extrn  disk_base:byte

;
; Public
;

                public  disk_driver
                public  disk_int

;
; Equates
;

Int_flag          equ     080h    ; interrupt occurance flag

Motor_wait        equ     37      ; two seconds of counts form motor turn off

Time_out          equ     80h     ; attachment failed to respond

Bad_seek          equ     40h     ; seek operation failed

Bad_nec           equ     20h     ; NEC controller has failed

Bad_crc           equ     10h     ; bad CRC on diskette read

Dma_boundry       equ     09h     ; attempt to DMA across 64K boundry

Bad_dma           equ     08h     ; DMA overrun on operation

Record_not_fnd    equ     04h     ; requested secotr not found

Write_protect     equ     03h     ; write attempted on write protected disk

Bad_addr_mark     equ     02h     ; address mark not found

Bad_cmd           equ     01h     ; bad command passed to diskette I/O

Dma               equ     00h     ; DMA channel 0 address reg port addr

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                           DISKETTE DRIVER                             |
; |                                                                       |
; |          Input:                                                       |
; |                                                                       |
; |                (AH) = 0                                               |
; |                     Reset diskette system.                            |
; |                     Hard reset to NEC, prepare command.               |
; |                     Reacall required on all drives.                   |
; |                                                                       |
; |                (AH) = 1                                               |
; |                     Read the status of the system into (AL)           |
; |                     Diskette_status from last op'n used               |
; |                                                                       |
; |                (AH) = 2                                               |
; |                     Read the desired sectors into memory              |
; |                                                                       |
; |                (AH) = 3                                               |
; |                     Write the desired sectors from memory             |
; |                                                                       |
; |                (AH) = 4                                               |
; |                     Verify the desired sectors                        |
; |                                                                       |
; |                (AH) = 5                                               |
; |                     Format the desired track                          |
; |                     For the format operation, the buffer pointer      |
; |                     (ES:BX) must point to the collection of           |
; |                     address fields is composed of 4 bytes (C,H,R,N)   |
; |                     where C = track number, H = head number           |
; |                     R = sector number, N = number of bytes per        |
; |                     sector ( 00=128,02=512,03=1024,04=2048,05=4096)   |
; |                     There must be one entry for every sector          |
; |                     on the track                                      |
; |                                                                       |
; |                (AH) = 6                                               |
; |                     Read sector ID                                    |
; |                     If used after read a track the first sector       |
; |                     read will be the second sector on the track       |
; |                                                                       |
; |                (AH) = 7                                               |
; |                     Read a track (used to position the disk for       |
; |                                   read sector id)                     |
; |                                                                       |
; |                (AH) = 8                                               |
; |                     Read deleted data                                 |
; |                                                                       |
; |                (AH) = 9                                               |
; |                     Write deleted data                                |
; |                                                                       |
; |                (AH) = A                                               |
; |                     Verify deleted data                               |
; |                                                                       |
; |          Registers for read/write/verify/format                       |
; |                                                                       |
; |                (DL) - drive number (0-1 allowed not value checked)    |
; |                (DH) - head number (0-1 allowed, not value checked)    |
; |                (CH) - track number (0-39, not value checked)          |
; |                (CL) - sector number (1-8, not value checked)          |
; |                (AL) - number of sectors (MAX = 8, not value checked)  |
; |                                                                       |
; |          Output:                                                      |
; |                                                                       |
; |                (AH) = status of operation                             |
; |                     80 - attachment failed to respond                 |
; |                     40 - seek operation failed                        |
; |                     20 - NEC controller has failed                    |
; |                     10 - bad CRC                                      |
; |                     09 - attempt to DMA across 64K boundry            |
; |                     08 - DMA overrun on operation                     |
; |                     04 - requested sector not found                   |
; |                     03 - write attempted on write prot disk           |
; |                     02 - address mark not found                       |
; |                     01 - bad command passed to diskette I/O           |
; |                                                                       |
; |                (CY) = 0 successful operation (AH=0 on return)         |
; |                (CY) = 1 failed operation (AH has error reason)        |
; |                                                                       |
; |                For read/write/verify                                  |
; |                     DS,BX,DX,CH,CL preserved                          |
; |                     AL = number of sectors actually read              |
; |                     ******* AL may not be correct if time out         |
; |                                error occurs                           |
; |                Note:                                                  |
; |                      If an error is reported by the diskette code     |
; |                      the appropriate action is to reset the diskette  |
; |                      then retry the operation. On read access, no     |
; |                      motor start delay is taken, so that three        |
; |                      retries are required on reads to ensure that     |
; |                      the problem is not due to motor start-up.        |
; |                                                                       |
; -------------------------------------------------------------------------

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                            DISK DATA                                  |
; |                                                                       |
; -------------------------------------------------------------------------

Seek_status       equ     3eh     ; drive recalibration status
                                  ; bit 3-0 = drive 3-0 needs recall
                                  ; before next seek if bit is = 0

Motor_status      equ     3fh     ; motor status
                                  ; bit 3-0 = drive 3-0 is currently
                                  ; running
                                  ; bit 7 = current operation is
                                  ; write, requires delay

Motor_count       equ     40h     ; time out counter form drive turn
                                  ; off

Diskette_status   equ     41h     ; single byte of return code
                                  ; info for status

Nec_status        equ     42h     ; status bytes form NEC   

Page

; #########################################################################
; #                                                                       #
; #                           DISK DRIVER                                 #
; #                                                                       #
; #########################################################################

Disk_driver     proc    far

                sti

                push    bx
                push    cx
                push    ds
                push    si
                push    di
                push    bp
                push    dx

                mov     bp,sp

                mov     si,40h
                mov     ds,si

                call    determine_command

                mov     bx,4
                call    get_parm

                mov     ds:[motor_count],ah
                mov     ah,ds:[diskette_status]

                cmp     ah,1
                cmc

                pop     dx
                pop     bp
                pop     di
                pop     si
                pop     ds
                pop     cx
                pop     bx

                ret     2         ; throw away saved flags

Disk_driver     endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                            DETERMINE COMMAND                          |
; |                                                                       |
; -------------------------------------------------------------------------

Determine_command proc  near

                mov     dh,al
                and     byte ptr ds:[motor_status],07fh

        Test_reset_operation:

                or      ah,ah
                jnz     test_status_operation

                jmp     disk_reset_operation

        Test_status_operation:

                dec     ah
                jnz     test_drive_range

                jmp     disk_status_operation

        Test_drive_range:

                mov     byte ptr ds:[diskette_status],0

                cmp     dl,4
                jb      test_read_operation

                jmp     bad_int_command    ; drive specified out of range

        Test_read_operation:

                dec     ah
                jnz     test_write_operation

                jmp     disk_read_operation

        Test_write_operation:

                dec     ah
                jnz     test_verify_operation

                jmp     disk_write_operation

        Test_verify_operation:

                dec     ah
                jnz     test_format_operation

                jmp     disk_verf_operation

        Test_format_operation:

                dec     ah
                jnz     test_read_id_operation

                jmp     disk_format_operation

        Test_read_id_operation:

                dec     ah
                jnz     test_read_track_operation

                jmp     read_id_operation

        Test_read_track_operation:

                dec     ah
                jnz     test_read_deleted_operation

                jmp     read_track_operation

        Test_read_deleted_operation:

                dec     ah
                jnz     test_write_deleted_operation

                jmp     read_deleted_data_operation

        Test_write_deleted_operation:

                dec     ah
                jnz     test_deleted_verify_operation

                jmp     write_deleted_data_operation

        Test_deleted_verify_operation:

                dec     ah
                jnz     bad_int_command

                jmp     verify_deleted_data_operation

        Bad_int_command:

                mov     byte ptr ds:[diskette_status],bad_cmd

                jmp     determine_command_return

        Disk_reset_operation:

                call    disk_reset

                jmp     determine_command_return

        Disk_status_operation:

                call    disk_status

                jmp     determine_command_return

        Disk_read_operation:

                mov     al,046h
                call    dma_setup

                jnc     read_call

                jmp     dma_error

        Read_call:

                mov     ah,066h
                call    rw_opn

                jmp     determine_command_return

        Disk_write_operation:

                or      byte ptr ds:[motor_status],80h

                mov     al,04ah
                call    dma_setup

                jnc     write_call

                jmp     dma_error

        Write_call:

                mov     ah,045h
                call    rw_opn

                jmp     determine_command_return

        Disk_verf_operation:

                mov     al,042h
                call    dma_setup

                jnc     verify_call

                jmp     dma_error

        Verify_call:

                mov     ah,066h
                call    rw_opn

                jmp     determine_command_return

        Disk_format_operation:

                or      byte ptr ds:[motor_status],80h

                mov     al,04ah
                call    dma_setup

                jnc     format_call

                jmp     dma_error

        Format_call:

                mov     ah,04dh
                call    rw_opn

                jmp     determine_command_return

        Read_id_operation:

                mov     ah,4ah
                call    rw_opn

                jmp     determine_command_return

        Read_track_operation:       

                mov     al,42h
                call    dma_setup

                jnc     read_track_call

                jmp     dma_error

        Read_track_call:

                mov     ah,42h
                call    rw_opn

                jmp     determine_command_return

        Read_deleted_data_operation:

                mov     al,046h
                call    dma_setup

                jnc     read_deleted_call

                jmp     dma_error

        Read_deleted_call:

                mov     ah,06ch
                call    rw_opn

                jmp     determine_command_return

        Write_deleted_data_operation:

                or      byte ptr ds:[motor_status],80h

                mov     al,04ah
                call    dma_setup

                jnc     write_deleted_call

                jmp     dma_error

        Write_deleted_call:

                mov     ah,049h
                call    rw_opn

                jmp     determine_command_return

        Verify_deleted_data_operation:

                mov     al,042h
                call    dma_setup

                jnc     verify_deleted_call

                jmp     dma_error

        Verify_deleted_call:

                mov     ah,06ch
                call    rw_opn

                jmp     determine_command_return

        Dma_error:

                mov     byte ptr ds:[diskette_status],dma_boundry
                mov     al,0

        Determine_command_return:

                ret

Determine_command endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                            DISK RESET                                 |
; |                                                                       |
; -------------------------------------------------------------------------

Disk_reset      proc    near

                mov     dx,03f2h

                cli

                mov     al,ds:[motor_status]
                mov     cl,4

                sal     al,cl

                test    al,20h
                jnz     motor_1

                test    al,40h
                jnz     motor_2

                test    al,80h
                jz      motor_0

                inc     al

        Motor_2:

                inc     al

        Motor_1:

                inc     al

        Motor_0:

                or      al,8

                out     dx,al

                mov     byte ptr ds:[seek_status],0
                mov     byte ptr ds:[diskette_status],0

                or      al,4

                out     dx,al

                sti

                call    chk_stat_2

                mov     al,ds:[nec_status]

                cmp     al,0c0h
                jz      drive_ok

                or      byte ptr ds:[diskette_status],bad_nec
                jmp     disk_reset_return

        Drive_ok:

                mov     ah,03h
                call    nec_output

                jc      disk_reset_return

                mov     bx,1
                call    get_parm

                jc      disk_reset_return

                mov     bx,3
                call    get_parm

        Disk_reset_return:

                ret

Disk_reset      endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                            DISK STATUS                                |
; |                                                                       |
; -------------------------------------------------------------------------

Disk_status     proc    near

                mov     al,ds:[diskette_status]

                ret

Disk_status     endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                             RW OPN                                    |
; |                                                                       |
; |         This routine performs the read/write/verify operation         |
; |                                                                       |
; -------------------------------------------------------------------------

Rw_opn         proc     near

               push     ax
               push     cx

               mov      cl,dl
               mov      al,1
               sal      al,cl

               cli

               mov      byte ptr ds:[motor_count],0ffh

               test     al,ds:[motor_status]
               jnz      motor_running

               and      byte ptr ds:[motor_status],0f0h
               or       ds:[motor_status],al

               sti

               mov      al,10h
               sal      al,cl
               or       al,dl
               or       al,0ch
      
               push     dx

               mov      dx,03f2h
               out      dx,al

               pop      dx

               test     byte ptr ds:[motor_status],80h
               jz       motor_running

               mov      bx,20
               call     get_parm

               or       ah,ah

        Test_wait_time:

               jz       motor_running

               sub      cx,cx

        Motor_wait_loop:

               loop     motor_wait_loop

               dec      ah

               jmp      test_wait_time

        Motor_running:
 
               sti

               pop      cx

               pop      ax

               cmp      ah,4ah
               je       do_not_seek

               push     ax

               call     seek

               pop      ax

        Do_not_seek:

               mov      bh,ah
               mov      dh,0

               jc       nec_error

               call     nec_output

               jc       nec_error

               mov      ah,[bp+1]

               sal      ah,1
               sal      ah,1

               and      ah,4
               or       ah,dl

               call     nec_output

               jc       nec_error

               cmp      bh,04dh
               jne      not_format_command

               mov      bx,7
               call     get_parm

               jc       nec_error

               mov      bx,9
               call     get_parm

               jc       nec_error

               mov      bx,15
               call     get_parm

               jc       nec_error

               mov      bx,17

               jmp      rw_opn_finish

        Not_format_command:

               cmp      bh,4ah
               jne      not_read_id_command

               jmp      rw_opn_complete

        Not_read_id_command:

               mov      ah,ch
               call     nec_output

               jc       nec_error

               mov      ah,[bp+1]
               call     nec_output

               jc       nec_error

               mov      ah,cl
               call     nec_output

               jc       nec_error

               mov      bx,7
               call     get_parm

               jc       nec_error

               mov      bx,9
               call     get_parm

               jc       nec_error

               mov      bx,11
               call     get_parm

               jc       nec_error

               mov      bx,13

        Rw_opn_finish:

               call     get_parm

               jc       nec_error

        Rw_opn_complete:

               call     wait_int

               jnc      motor_off

        Nec_error:

               jmp      flush_result_buffer

        Motor_off:

               call     results        

               jc       rw_opn_return

               cld

               mov      si,nec_status
               lodsb

               and      al,0c0h
               jz       rw_opn_ok

               cmp      al,040h
               jnz      bad_nec_controller

               lodsb
               sal      al,1

               mov      ah,record_not_fnd
               jc       rw_fail

               sal      al,1
               sal      al,1
               mov      ah,bad_crc
               jc       rw_fail

               sal      al,1
               mov      ah,bad_dma
               jc       rw_fail

               sal      al,1
               sal      al,1
               mov      ah,record_not_fnd
               jc       rw_fail

               sal      al,1
               mov      ah,write_protect
               jc       rw_fail

               sal      al,1
               mov      ah,bad_addr_mark
               jc       rw_fail

        Bad_nec_controller:

               mov      ah,bad_nec

        Rw_fail:

               or       ds:[diskette_status],ah

               call     num_trans

               jmp      rw_opn_return

        Flush_result_buffer:

               call     results

               jmp      rw_opn_return

        Rw_opn_ok:

               call     num_trans

               xor      ah,ah

        Rw_opn_return:

               ret

Rw_opn         endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                              NEC OUTPUT                               |
; |                                                                       |
; |      This routine sends a byte to the NEC controller                  |
; |      After testing for correct direction and controller ready         |
; |      This routine will time out if the byte is not accepted           |
; |      within a reasonable amount of time, setting the diskette staus   |
; |      on completion                                                    |
; |                                                                       |
; |   Input                                                               |
; |      (AH)  byte to be output                                          |
; |                                                                       |
; |   Output                                                              |
; |      CY = 0 success                                                   |
; |      CY = 1 failure -- DISKETTE_STATUS updated                        |
; |                                                                       |
; -------------------------------------------------------------------------

Nec_output      proc    near

                push    dx
                push    cx

                mov     dx,03f4h
                xor     cx,cx

        Get_status_loop_1:

                in      al,dx

                test    al,040h
                jz      reset_the_count

                loop    get_status_loop_1

                jmp     time_out_error

        Reset_the_count:

                xor      cx,cx

        Get_status_loop_2:

                in       al,dx

                test     al,080h
                jnz      output_byte

                loop     get_status_loop_2

        Time_out_error:

                or       byte ptr ds:[diskette_status],time_out

                stc

                jmp     nec_output_return

        Output_byte:

                mov     al,ah
                mov     dx,03f5h

                out     dx,al

                clc

         Nec_output_return:

                pop     cx
                pop     dx

                ret

Nec_output      endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                             GET PARM                                  |
; |                                                                       |
; |    This routine fetches the indexed pointer from the DISK_BASE        |
; |    block                                                              |
; |    A byte from that table is then moved into AH, the index of that    |
; |    byte being the parm in BX                                          |
; |                                                                       |
; |    Entry --                                                           |
; |      BX = index of byte to be ftetched * 2                            |
; |           if the low bit of BX is on, the byte is immediately         |
; |           output to the NEC controller                                |
; |                                                                       |
; |    Exit --                                                            |
; |      AH = that byte from block                                        |
; |                                                                       |
; -------------------------------------------------------------------------

Get_parm       proc     near

               shr      bx,1

               mov      si,offset disk_base

               mov      ah,cs:[si+bx]

               jnc      get_parm_return

               call     nec_output

        Get_parm_return:

               ret

Get_parm       endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                              SEEK                                     |
; |                                                                       |
; |     This routine will move the head on the named drive                |
; |     to the named track, if the drive has not been accessed            |
; |     since the drive reset command was issued, the drive will be       |
; |     recailbrated.                                                     |
; |                                                                       |
; |     Input                                                             |
; |       (DL) = drive to seek on                                         |
; |       (CH) = track to seek to                                         |
; |                                                                       |
; |     Output                                                            |
; |       CY = 0 success                                                  |
; |       CY = 1 failure -- DISKETTE_STATUS set accordingly               |
; |       (AX) destroyed                                                  |
; |                                                                       |
; -------------------------------------------------------------------------

Seek            proc    near

                mov     al,1

                push    cx

                mov     cl,dl
                rol     al,cl

                pop     cx

                test    al,ds:[seek_status]
                jnz     no_recall

                or      ds:[seek_status],al

                mov     ah,07h
                call    nec_output

                jc      seek_return

                mov     ah,dl
                call    nec_output

                jc      seek_return

                call    chk_stat_2

                jc      seek_return

        No_recall:

                mov     ah,0fh
                call    nec_output

                jc      seek_return

                mov     ah,dl
                call    nec_output

                jc      seek_return

                mov     ah,ch
                call    nec_output

                jc      seek_return

                call    chk_stat_2

                pushf

                mov     bx,18
                call    get_parm

                push    cx

        Head_settle_loop:

                mov     cx,550
                or      ah,ah
                jz      recover_state

        Head_delay_loop:

                loop    head_delay_loop

                dec     ah

                jmp     head_settle_loop

        Recover_state:

                pop     cx
                popf

        Seek_return:

                ret

Seek            endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                              DMA SETUP                                |
; |                                                                       |
; |    This routine sets up the DMA for read/write/verify operations      |
; |                                                                       |
; |    Input                                                              |
; |      (AL) = mode byte for the DMA                                     |
; |      (ES:BX) - address to read/write the data                         |
; |                                                                       |
; |    Output                                                             |
; |      (AX) destroyed                                                   |
; |                                                                       |
; -------------------------------------------------------------------------

Dma_setup       proc    near

                push    cx

                out     dma+12,al

                out     dma+11,al

                mov     ax,es

                mov     cl,4
                rol     ax,cl
                mov     ch,al
                and     al,0f0h
                add     ax,bx
                jnc     no_carry

                inc     ch

        No_carry:

                push    ax

                out     dma+4,al

                mov     al,ah
                out     dma+4,al

                mov     al,ch
                and     al,0fh
                out     081h,al

                mov     ah,dh
                sub     al,al
                shr     ax,1

                push    ax

                mov     bx,6
                call    get_parm

                mov     cl,ah

                pop     ax

                shl     ax,cl
                dec     ax

                push    ax

                out     dma+5,al

                mov     al,ah
                out     dma+5,al

                pop     cx
                pop     ax

                add     ax,cx

                pop     cx

                mov     al,2
                out     dma+10,al

                ret

Dma_setup       endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                             CHK STAT 2                                |
; |                                                                       |
; |      This routine handles ths interrupt recieved after a              |
; |      recalibrate, seek, or reset to the adapter. The interrupt        |
; |      is waited for, the interrupt status sensed. and the result       |
; |      returned to the caller.                                          |
; |                                                                       |
; |      Input                                                            |
; |            none                                                       |
; |                                                                       |
; |      Output                                                           |
; |            CY = 0 success                                             |
; |            CY = 1 failure -- error is in DISKETTE_STATUS              |
; |            (AX) destroyed                                             |
; |                                                                       |
; -------------------------------------------------------------------------

Chk_stat_2      proc    near

                call    wait_int

                jc      chk_stat_2_return

                mov     ah,08h
                call    nec_output

                jc      chk_stat_2_return

                call    results

                jc      chk_stat_2_return

                mov     al,ds:[nec_status]
                and     al,060h

                cmp     al,060h
                jz      chk_stat_2_error

                clc

                jmp     chk_stat_2_return

        Chk_stat_2_error:

                or      byte ptr ds:[diskette_status],bad_seek

                stc

        Chk_stat_2_return:

                ret

Chk_stat_2      endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                             WAIT INT                                  |
; |                                                                       |
; |  This routine waits for an interrupt to occur a time out routine      |
; |  takes place durning the wait, so that an error nay be returned       |
; |  if the drive is not ready.                                           |
; |                                                                       |
; |  Input                                                                |
; |        none                                                           |
; |                                                                       |
; |  Output                                                               |
; |        CY = 0 success                                                 |
; |        CY = 1 failure -- DISKETTE_STATUS is set accordingly           |
; |        (AX) destroyed                                                 |
; |                                                                       |
; -------------------------------------------------------------------------

Wait_int        proc    near

                sti

                push    bx
                push    cx

                mov     bl,2
                xor     cx,cx

        Wait_count_loop:

                test    byte ptr ds:[seek_status],int_flag
                jnz     wait_int_return

                loop    wait_count_loop

                dec     bl
                jnz     wait_count_loop

                or      byte ptr ds:[diskette_status],time_out

                stc

        Wait_int_return:

                pushf

                and     byte ptr ds:[seek_status],not int_flag

                popf

                pop     cx
                pop     bx

                ret

Wait_int        endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                              RESULTS                                  |
; |                                                                       |
; |        This routine will read anytheing that the NEC controller       |
; |        has to say following an interrupt.                             |
; |                                                                       |
; |     Input                                                             |
; |           none                                                        |
; |                                                                       |
; |     Output                                                            |
; |           CY = 0 successful transfer                                  |
; |           CY = 1 failure -- time out in waiting for status            |
; |           (AH) destroyed                                              |
; |                                                                       |
; -------------------------------------------------------------------------

Results         proc     near

                cld

                mov      di,nec_status

                push     cx
                push     dx
                push     bx

                mov      bl,7

        Input_loop:

                xor      cx,cx
                mov      dx,03f4h

        Wait_for_status:

                in       al,dx

                test     al,080h
                jnz      get_status_reg_again

                loop     wait_for_status

                or       byte ptr ds:[diskette_status],time_out

        Set_error_return:

                stc

                jmp      results_return

        Get_status_reg_again:

                in       al,dx

                test     al,040h
                jnz      read_stat

        Nec_failure:

                or       byte ptr ds:[diskette_status],bad_nec

                stc

                jmp     results_return

        Read_stat:

                inc     dx

                in      al,dx

                mov     ds:[di],al

                inc     di
                mov     cx,10

        Kill_time_for_nec_loop:

                loop    kill_time_for_nec_loop

                dec     dx

                in      al,dx

                test    al,010h
                jz      results_return

                dec     bl

                jnz     input_loop

                or      byte ptr ds:[diskette_status],bad_nec

                stc

        Results_return:

                pop     bx
                pop     dx
                pop     cx

                ret

Results         endp

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                             NUM TRANS                                 |
; |                                                                       |
; |     This routine calculates the number of sectors that were           |
; |     actually transferred to/from the diskette                         |
; |                                                                       |
; |    Input                                                              |
; |           (CH) = cyclinder of operation                               |
; |           (CL) = start sector of operation                            |
; |                                                                       |
; |    Output                                                             |
; |           (AL) = number actually transferred                          |
; |           no other registers modified                                 |
; |                                                                       |
; -------------------------------------------------------------------------

Num_trans       proc    near

                mov     al,ds:[nec_status+3]

                cmp     al,ch
                mov     al,ds:[nec_status+5]
                jz      num_trans_return

                mov     bx,8
                call    get_parm

                mov     al,ah
                inc     al

        Num_trans_return:

                sub      al,cl

                ret

Num_trans       endp

Page

; #########################################################################
; #                                                                       #
; #                              DISK INT                                 #
; #                                                                       #
; #    Input                                                              #
; #          none                                                         #
; #                                                                       #
; #    Output                                                             #
; #          the interrupt flag is set is SEEK_STATUS                     #
; #                                                                       #
; #########################################################################

Disk_int        proc    near

                sti

                push    ax
                push    ds

                mov     ax,40h
                mov     ds,ax

                or      byte ptr ds:[seek_status],int_flag
                mov     al,20h

                out     20h,al

                pop     ds
                pop     ax

                iret

Disk_int        endp

Code_seg        ends

                end
    pp  a        ieDs_n    edCd_e    ed        ed
  p a    esn  dde  d    d pa  es dd d  dp e dd ped e    pp  d                