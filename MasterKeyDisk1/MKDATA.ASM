Name            MKDATA

Title           Master_key_data

Subttl          Data

Page 60,132

; *************************************************************************
; |                                                                       |
; |                 (C)opyright 1983 Software Laboratories Inc.           |
; |                                                                       |
; |                     Author Cameron L. Wolff                           |
; |                                                                       |
; *************************************************************************

; Code segment

Code_seg        segment public 'code'
    
                public keyio_segment,end_data
                public keyint_offset,keyint_segment,Keyio_offset,dta_seg
                public keyint_segment,number_of_drives,target_drive
                public source_drive,select_menu_message,Main_menu_return_seg
                public main_menu_return_off,select_menu_title
                public depress_function_key_message,track_number
                public head_number,sector_counter
                public disk_base,bytes_per_sector,retry,old_track_number
                public format_parameter_block,read_write_parameter_block
                public end_of_track,buffer_head,selection_complete_message
                public buffer_tail,kb_flag
                public kb_buffer_end,legal_characters,kb_buffer
                public drive_not_ready_message,seek_failed_message
                public nec_failed_message,crc_data_error_message
                public crc_id_error_message,dma_boundry_error_message
                public dma_overrun_error_message,sector_not_found_message
                public track_not_formatted_message,esc_message,map_message
                public read_message,format_message,write_message
                public verify_message,source_drive_message
                public target_drive_message,source_drive_number_message
                public target_drive_number_message,date_message
                public are_you_sure_message,yes_message,no_message
                public esc_message,exit_message
                public modulos_10_byte,modulos_10_word
                public arrow_message,function_key_message
                public left_frame_message,parameter_pointer
                public right_frame_message,master_key_message
                public bar_line_message,space_line_message,version_message
                public current_disk_message,source_diskette_message
                public target_diskette_message,current_track_message
                public row_1_message,row_2_message,insert_source_message
                public insert_source_number_message,insert_target_message
                public insert_target_number_message,return_message
                public current_track_message,mult_three,use_key_message
                public sector_message,sector_number_message
                public old_disk_int_seg,old_disk_int_off
                public old_disk_io_seg,old_disk_io_off
                public bad_command_message,Hold_on_message,one_drive_message
                public current_track_number_message,old_track_number_message
                public esc_menu_message,select_source_drive_message
                public select_target_drive_message,drive_a_selection_message
                public drive_b_selection_message,status_message_pointer
                public diskette_write_prot_message,sector_count
                public sectors_on_track,sectors_on_track_pointer
                public map_not_formatted_message
                public lowest_valid_sector,verify_sector_block
                public verify_pointer,temporary_parameter_block
                public temporary_pointer,format_pointer,help_message
                public help_return_message
                public read_instruction,read_instruction_pointer
                public write_instruction,write_instruction_pointer
                public verify_instruction,verify_instruction_pointer
                public unformat_message,second_retry,number_of_tracks_to_read
                public track_counter,read_write_parameter_pointer
                public format_parameter_pointer,read_instruction_ptr
                public write_instruction_ptr,verify_instruction_ptr
                public dta_seg_pointer,current_side_message,side_1_message
                public side_0_message

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                          PROGRAM MESSAGES                             |
; |                                                                       |
; |                Messages to be used by Master Key                      |
; |                                                                       |
; -------------------------------------------------------------------------

Select_menu_title       db   76,'<<<<<<<<<<<<<<<< '
                        db      '(C)opyright 1983 Software Laboratories Inc'
                        db      ' >>>>>>>>>>>>>>>>'

Master_key_message     db   13,'Master ',0ech,0b7h,' Key'

Select_menu_message     db   15,'Master Key Help'
                        db   13,'Copy Diskette'
                        db   13,'Select Drives'

Arrow_message           db   07,'<',0cdh,0cdh,0cdh,0cdh,0cdh,'>'

Esc_message             db   03,'ESC'

Exit_message            db   15,'Exit Master Key'

Left_frame_message      db   08,176,176,177,177,178,178,219,219
Right_frame_message     db   08,219,219,178,178,177,177,176,176

Bar_line_message        db   79h
                        db   79 dup (0cdh)

Space_line_message      db   79h
                        db   79 dup (' ')

Current_side_message    db   12,'Current Side'
Side_0_message          db   08,' Side 0 '
Side_1_message          db   08,' Side 1 '

; Operation messages

Map_message             db   23,'Mapping Source Diskette'

Read_message            db   23,'Reading Source Diskette'

Format_message          db   26,'Formatting Target Diskette'

Unformat_message        db   28,'Unformatting Target Diskette'

Write_message           db   23,'Writing Target Diskette'

Verify_message          db   25,'Verifying Target Diskette'

Source_drive_message    db   15,'Source Drive '
Source_drive_number_message db 'A:'

Target_drive_message    db   15,'Target Drive '
Target_drive_number_message db 'B:'

Date_message            db   10,'01-01-1981'

Are_you_sure_message    db   14,'Are You Sure ?'
Yes_message             db   05,' Yes '
No_message              db   04,' No '

; Disk error Message

Drive_not_ready_message db   58,' Drive NOT Ready -- Please Fix -- Depress '
                        db      11h,0c4h,0d9h,' to Continue '

Seek_failed_message     db   40,' Seek Failed -- Depress ',11h,0c4h,0d9h
                        db     ' to Continue '

Nec_failed_message      db   47,' NEC Controller Bad -- Depress '
                        db      11h,0c4h,0d9h,' to Continue '

Crc_data_error_message  db   52,' CRC Error in Data Field -- Depress '
                        db      11h,0c4h,0d9h,' to Continue '

Crc_id_error_message    db   50,' CRC Error in ID Field -- Depress '
                        db      11h,0c4h,0d9h,' to Continue '

Dma_boundry_error_message db 46,' DMA Boundry Error -- Depress '
                          db    11h,0c4h,0d9h,' to Continue '

Dma_overrun_error_message db 46,' DMA Overrun Error -- Depress '
                          db    11h,0c4h,0d9h,' to Continue '

Sector_not_found_message  db 45,' Sector NOT Found -- Depress '
                          db     11h,0c4h,0d9h,' to  Continue '

Diskette_write_prot_message db 67,' Diskette Write Protected -- Please '
                            db    'Fix -- Depress ',11h,0c4h,0d9h
                            db    ' to Continue '

Track_not_formatted_message db 48,' Track NOT Formatted -- Depress '
                            db     11h,0c4h,0d9h,' to Continue '

Bad_command_message       db  40,' Bad Command -- Depress '
                          db     11h,0c4h,0d9h,' to Continue '

Map_not_formatted_message db  19,'Track NOT Formatted'

Depress_function_key_message db  20,'Depress FUNCTION key'

Function_key_message      db  02,'F1'

Current_disk_message      db  12,'Current Disk'

Source_diskette_message   db  17,' Source Diskette '

Target_diskette_message   db  17,' Target Diskette '

Current_track_message     db  59
                          db  22 dup (196)
                          db     ' Current Track '
                          db  22 dup (196)

Current_track_number_message     db  4,221,'  ',222
Old_track_number_message         db  4,'    '

Row_1_message             db  59,'00 01 02 03 04 05 06 07 08 09 10 11 12 13 '
                          db     '14 15 16 17 18 19'

Row_2_message             db  59,'20 21 22 23 24 25 26 27 28 29 30 31 32 33 '
                          db     '34 35 36 37 38 39'

Insert_source_message     db  41,'Insert Source Diskette in Source Drive '
Insert_source_number_message db  ' :'

Insert_target_message     db  41,'Insert Target Diskette in Target Drive '
Insert_target_number_message db  ' :'

Return_message            db  22,'Depress ',11h,0c4h,0d9h,' When Ready'

Mult_three                db  03

Sector_message            db  17,'Sector Number '
Sector_number_message     db  '   '

Esc_menu_message          db  26,' Depress ESC to Stop Copy '

Use_key_message           db  34,'Use ',19h,' ',18h,' ',1bh,' ',1ah,' Keys '
                          db     'to Select Drives '

Select_source_drive_message db 21,' Select Source Drive '

Select_target_drive_message db 21,' Select Target Drive '

Drive_a_selection_message   db 4,' A: '

Drive_b_selection_message   db 4,' B: '

One_drive_message           db 65,' There is only ONE drive, Can not Select,'
                            db    ' Depress ',11h,0c4h,0d9h
                            db    ' to Continue '

Hold_on_message             db 44,' Hold on to Your Britches Will Be Done '
                            db    'Soon '

Selection_complete_message  db 35,'Depress ',11h,0c4h,0d9h
                            db    ' When Selection Complete'

; Help messages

Help_return_message    db  38,' Depress ',11h,0c4h,0d9h
                       db     ' to Continue, ESC to exit '

Help_message label byte

       db 60,'                  Welcome to Master Key                     '
       db 60,'                                                            '
       db 60,'In order to use Master Key  depress the function key of your'
       db 60,'choice. They are as follows;                                '
       db 60,'                                                            '
       db 60,'     F1  Select source drive and/or target drive            '
       db 60,'     F2  Make a copy of source diskette onto target diskette'
       db 60,'     F3  Master Key help                                    '
       db 60,'                                                            '
       db 0ffh  ; end of first window ---------------

       db 60,'         Function Key 1 Selection -> Select Drives          '
       db 60,'For systems  that have  only one floppy  drive you will  not'
       db 60,'be able to change source or target drives.  On a system with'
       db 60,'2 or more  floppy drives you may  select the source drive as'
       db 60,'drive A  or drive  B.  The same may  be done for  the target'
       db 60,'drive. If the source drive and the target drive are the same'
       db 60,'you  will be  required  to swap diskettes.  Master Key  will'
       db 60,'display a  message to inform  you when to  perform the swap.'
       db 60,'                                                            '
       db 0ffh  ; end of second window --------------

       db 60,'         Function Key 2 Selection -> Copy Disk              '
       db 60,'Master Key will copy  many copy protected disks.  There will'
       db 60,'be some copy  protection schemes that Master Key will not as'
       db 60,'of yet be able to copy. Also new copy protection schemes may'
       db 60,'be introduced that may be unfamiliar to Master Key. For this'
       db 60,'reason Master Key  is a  "LIVE PROGRAM". Software Labs  will'
       db 60,'continue  to research  copy  protection  methods and as  new'
       db 60,'solutions are developed they will be added to Master Key. In'
       db 60,'other  words  Master  Key  will  continue  to  evolve.      '
       db 0ffh  ; end of third window ---------------

       db 60,'Please let us at Software Labs know how  Master Key performs'
       db 60,'for you. Drop us a line listing the programs that Master Key'
       db 60,'could and could not copy.  We will inform you as to when the'
       db 60,'copying power of  Master Key has been modified to copy other'
       db 60,'copy  protection  schemes.                                  '
       db 60,'                * * *  C A U T I O N  * * *                 '  
       db 60,'Master Key  is to  be used  only for the  purpose of  making'
       db 60,'BACKUP copies of your valuable programs for use by the owner'
       db 60,'Any  other use may  be a  Violation  of the  Copyright  Law.'
       db 0ffh  ; end of fourth window ---------------

       db 60,'        Function Key 3 Selection -> Master Key Help         '
       db 60,'You  have  just  viewed  the   Master  Key   help  function.'
       db 60,'If you have  any other questions  or need assistance you may'
       db 60,'talk with our  software support group.  The hours are Monday'
       db 60,'thur  Friday  between  3  -  5  pm  Eastern  Standard  Time.'
       db 60,'Customer support phone number is  614 - 889 - 5083, or write'
       db 60,'to:                Software Laboratories Inc.               '
       db 60,'                   6924 Riverside Drive                     '
       db 60,'                   Dublin, Ohio 43017                       '
       db 00    ; end of help -------------

Version_message db 11,'Version 3.0'

Author db 'Authored by Cameron L. Wolff'
Copyright db '(C)opyright 1983 Software Laboratories Inc.'

Page

; -------------------------------------------------------------------------
; |                                                                       |
; |                         PROGRAM STORAGE                               |
; |                                                                       |
; |               Variables to be used by Master Key                      |
; |                                                                       |
; -------------------------------------------------------------------------

; Interrupt pointers

Keyint_offset           dw   0000h
Keyint_segment          dw   0000h

Keyio_offset            dw   0000h
Keyio_segment           dw   0000h

Main_menu_return_off    dw   0000h
Main_menu_return_seg    dw   0000h

Old_disk_int_off        dw   0000h
Old_disk_int_seg        dw   0000h

Old_disk_io_off         dw   0000h
Old_disk_io_seg         dw   0000h

; Program variables

Number_of_tracks_to_read     db    00h
Number_of_drives             dw    00h
Track_counter                db    00h
Sector_counter               db    00h
Target_drive                 db    00h
Source_drive                 db    00h
Track_number                 db    00h
Head_number                  dw    00h
Old_track_number             db    00h
Sector_count                 db    00h
Retry                        db    00h
Second_retry                 db    00h
Modulos_10_byte              db    0ah
Modulos_10_word              dw    000ah
Status_message_pointer       dw    0000h
Lowest_valid_sector          db    00h

; Disk Parameter block -------------------------

Disk_base               db   0cfh
                        db   02h
                        db   25h
Bytes_per_sector        db   02h
End_of_track            db   08h
                        db   2ah
                        db   0ffh
                        db   050h
                        db   0f6h
                        db   19h
                        db   04h

; Key board buffer -----------------------------

Kb_flag                 db   00h

Legal_characters        db   16,3bh,3ch,3dh,3eh,3fh,40h,41h,42h,43h,44h
                        db      4bh,4dh,48h,50h,1ch,01h

Buffer_head             dw   offset kb_buffer
Buffer_tail             dw   offset kb_buffer

Kb_buffer               dw 16 dup (00)

Kb_buffer_end           label word

                        dw 0000            ; buffer

; Block to handle normal or deleted read,write,verify

Read_instruction_pointer      dw     0000h
Read_instruction_ptr          dw     0000h
Read_instruction              db     1200 dup (00h)

Write_instruction_pointer     dw     0000h
Write_instruction_ptr         dw     0000h
Write_instruction             db     1200 dup (00h)

Verify_instruction_pointer    dw     0000h
Verify_instruction_ptr        dw     0000h
Verify_instruction            db     1200 dup (00h)

; Read parameter block -------------------------

Read_write_parameter_pointer  dw   0000h

Parameter_pointer             dw   0000h

Read_write_parameter_block    db 4880 dup (00)

; Format parmater block

Format_parameter_pointer   dw   0000h

Format_pointer             dw   0000h

Format_parameter_block     db 4960 dup (00)

; Temparary parameter block

Temporary_pointer          dw   0000h

Temporary_parameter_block  db 61 dup (00)

; Used to mark valid sectors in mixed sector format

Verify_pointer             dw   0000h

Verify_sector_block        db 15 dup (00)

; Same as sector status except status bytes striped out

Sectors_on_track_pointer   dw  0000h

Sectors_on_track           db 69 dup (00)

; DTA segment

Dta_seg_pointer          dw  0000h

Dta_seg                  dw  0000h

End_data                 db  00

Code_seg        ends

                end     b 0

oesg    ns

        n  b0
eg  s
     0e s  0     b6 u 0)

 T emnDasgpitr     w 00Dasg         w 00Eddt     t  ‰ğƒê5 ;wº úü u¡ À uş½)ğƒò ãÛ> tº 	!
åÍº 	!çÆÿt¬0
_ 
