;
; Cw_48.asm
;
; Created: 09.10.2020 17:11:35
; Author : IAmTheProgramer
;


                  .CSEG
                  .ORG 0 RJMP _main 
                  .ORG OC1Aaddr RJMP _timer_isr 
                  .ORG 0x000B RJMP   _Pin_B0_isr
       
       _timer_isr:                   
                  reti                            

       _Pin_B0_isr:
                  PUSH R16
                  RCALL NumberToDigits
                  INC PulseEdgeCtrL
                  CLR R16 
                  CP PulseEdgeCtrL,R16 
                  POP R16
                  BREQ  _Pin_B0_isr_end   
                  RETI                    
      _Pin_B0_isr_end:
                  INC PulseEdgeCtrH             
                  RETI
                  


               .MACRO SET_DIGIT
                  PUSH R16
                  PUSH R17
                  PUSH R30
                  PUSH R31
                  LDI R17,@0 
                  RCALL SegNumber
                  SBRC R17,1
                  MOV R16,Digit_0
                  SBRC R17,2
                  MOV R16,Digit_1
                  SBRC R17,3
                  MOV R16,Digit_2
                  SBRC R17,4
                  MOV R16,Digit_3
                  RCALL DigitTo7segCode 
                  OUT Segments_P,R16
                  OUT Digits_P,R17
                  POP R31
                  POP R30 
                  POP R17
                  POP R16
               .ENDMACRO

               .MACRO DELAY
                  PUSH R16
                  PUSH R17
                  LDI R16,LOW(@0)   
                  LDI R17,HIGH(@0)  
                  RCALL DelayInMs 
                  POP R17
                  POP R16
               .ENDMACRO

                .EQU Digits_P=PORTB     
                .EQU Segments_P=PORTD    
                .DEF Digit_0 = R2
                .DEF Digit_1 = R3
                .DEF Digit_2 = R4
                .DEF Digit_3 = R5
                .DEF PulseEdgeCtrL=R0
                .DEF PulseEdgeCtrH=R1
                .DEF QCtrL=R24
                .DEF QCtrH=R25
          _main:
                SEI
                LDI R16,12
                OUT TCCR1B,R16
                LDI R16,high(31250)
                OUT OCR1AH,R16
                LDI R16,LOW(31250)
                OUT OCR1AL,R16
                LDI R16,64
                OUT TIMSK,R16
                CLR R16
                OUT TCNT1L,R16
                OUT TCNT1H,R16
                LDI R16,32
                OUT GIMSK ,R16
                LDI R16,1
                OUT PCMSK ,R16
    
                CLR R16
                MOV Digit_0,R16 
                MOV Digit_1,R16
                MOV Digit_2,R16
                MOV Digit_3,R16
                OUT DDRB,R16
                LDI R16,255
                OUT PORTB,R16
                LDI R16,0x7F             
                LDI R17,2 
                OUT DDRD,R16
                OUT Segments_P,R16
                OUT DDRB,R17  
                CLR PulseEdgeCtrL
                CLR PulseEdgeCtrL
                CLR PulseEdgeCtrH
      MainLoop: 
                LDI QCtrL,LOW(9999)
                LDI QCtrH,HIGH(9999)
                CP PulseEdgeCtrL,QCtrL
                CPC PulseEdgeCtrH,QCtrH
                BREQ MainLoop-2
                SET_DIGIT 0
                DELAY 1
                SET_DIGIT 1
                DELAY 1
                SET_DIGIT 2
                DELAY 1
                SET_DIGIT 3
                DELAY 1 
                RJMP MainLoop   
                RETI
 NumberToDigits:
                PUSH XL
                PUSH XH
                PUSH YL
                PUSH YH
                MOV XL,PulseEdgeCtrL
                MOV XH,PulseEdgeCtrH
                LDI  YH,HIGH(1000)
                LDI  YL,LOW(1000)
                RCALL Divide
                MOV  Digit_0,YL
                LDI  YL,LOW(100)
                LDI  YH,HIGH(100)
                RCALL Divide
                MOV  Digit_1,YL
                LDI  YL,LOW(10)
                LDI  YH,HIGH(10)
                RCALL Divide
                MOV  Digit_2,YL
                LDI  YL,LOW(1)
                LDI  YH,HIGH(1)
                RCALL Divide
                MOV  Digit_3,YL
                POP YH
                POP YL
                POP XH
                POP XL
                RET

    Divide :   
               PUSH R25
               PUSH R24
               CLR R24
               CLR R25
    DivideLoop:
               CP XL,YL
               CPC XH,YH
               BRLO DivideEnd 
               ADIW QCtrH:QCtrL,1 
               SUB XL,YL
               SBC XH,YH
               BRBS 1,DivideEnd              
               RJMP DivideLoop
    DivideEnd: 
               MOV YL,QCtrL
               MOV YH,QCtrH
               POP R24
               POP R25
               RET  

      SegNumber:
               LDI R30, LOW(SegNumberData<<1) 
               LDI R31, HIGH(SegNumberData<<1)
               ADD R30,R17
               LPM R17,Z    
               RET
               SegNumberData: .db 2, 4, 8, 16


      DigitTo7segCode:
               LDI R30, LOW(SevenSegCodeData<<1) 
               LDI R31, HIGH(SevenSegCodeData<<1)
               ADD R30,R16
               LPM R16,Z  
               RET
               SevenSegCodeData: .db 0x3F, 0x06, 0x5B,0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F     


      DelayInMs: 
               PUSH R24
               PUSH R25
               MOV R24,R16
               MOV R25,R17 
               SBIW R24,0
               BRBS 1,DelayInMsEnd
      DelayInMsLoop:
               RCALL DelayOneMs
               SBIW R24,1
               BRBS 1,DelayInMsEnd
               RJMP DelayInMsLoop
      DelayInMsEnd:
               POP R25
               POP R24
               RET

      DelayOneMs:
               PUSH R24
               PUSH R25
               LDI R24,52
               LDI R25,5
      DelayOneMsLoop:
               NOP
               SBIW R24,1
               BRBS 1,DelayOneMsEnd
               RJMP DelayOneMsLoop
      DelayOneMsEnd:
               POP R25
               POP R24
               RET 