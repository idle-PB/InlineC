#ma_format_u8      = 1
#ma_format_s16     = 2     
#ma_format_s24     = 3     
#ma_format_s32     = 4
#ma_format_f32     = 5

#ma_device_type_capture =2   ;records from an input microphone or stereo mix
#ma_device_type_duplex = 3   ;records from input sources mic or stereo mix and plays back     
#ma_device_type_loopback = 4 ;windows only captures what's currently playing  

Interface iSoundRecorder 
  EnumDevices()
  NextDevice() 
  IsDefault(device.s)
  SetFile(filename.s)
  Config(device.s,format=#ma_format_s16,sampleRate=44100,mode=#ma_device_type_capture) 
  Monitor(*EffectsCB=0)
  Start()
  Stop(samplerate=44100)
  Free()
EndInterface 

Import "SoundRecorder.lib" 
  InitSoundRecorder() 
EndImport   

;-test 

Procedure.f CubicAmplifier(input.f)
    Protected  output.f, temp.f
    If input < 0.0
       temp = input + 1.0
       output = (temp * temp * temp) - 1.0
    Else
       temp = input - 1.0
       output = (temp * temp * temp) + 1.0
    EndIf    
          
    ProcedureReturn output;
  EndProcedure 
  
  Macro FUZZ(x)
    CubicAmplifier(CubicAmplifier(CubicAmplifier(x)))
  EndMacro
  
  Procedure fuzzCallback(*input,numframes,timeSeconds.d)
    
    Protected *pfIn.float = *input 
    Protected i
                 
    If *input <> 0
      While i < numframes
        *pfIn\f = FUZZ(*pfIn\f)   
        *pfin + 4
        i + 4
      Wend 
    EndIf 
    
  EndProcedure 
  
  Procedure RMSSignal(*input,numframes,timeseconds.d) 
    Protected rms.f,db.f, *pfIn.float = *input 
    If *input <> 0
      While i < numframes
        rms + (*pfIn\f * *pfIn\f)   
        *pfin + 4
        i + 4
      Wend 
    EndIf 
    
    DB = 20 * Log10(Sqr(rms/numframes))
    
    PrintN("Peek RMS DB " + StrF(DB,2))  
    
  EndProcedure  
  
    
InitSound()

OpenConsole()   

filename.s = GetTemporaryDirectory()+"tempwav.wav"

soundRec.iSoundRecorder = InitSoundRecorder() 

soundRec\SetFile(filename)

soundRec\EnumDevices()
Repeat
  device.s = PeekS(soundRec\NextDevice())   
  If soundRec\IsDefault(device)
    Debug "Is default Capture device index = " + device
    Break  
  EndIf 
Until device = ""  

PrintN("Init Recorder") 

soundRec\Config("",#ma_format_f32,44100,#ma_device_type_duplex)       ;record on default input and playback 
;soundRec\Config(device,#ma_format_s16,44100)                          ;record on selected input 
;soundRec\Config(device,#ma_format_s16,44100,#ma_device_type_loopback)  ;record on whats being currently played on speaker

PrintN("Monitoring Press Enter  to record") 

soundRec\Monitor(@fuzzCallback()) ;distort with cubic amp
soundRec\Monitor(@RMSSignal())    ;adds to call back chain note this isn't ideal as it's blocking  

Input()  

PrintN("Press enter tostart recording") 


soundRec\Start()

PrintN("Recording press enter to stop") 
Input();

soundRec\Stop()

snd = LoadSound(-1,filename) 
If snd 
  PlaySound(snd) 
EndIf   

PrintN("Stopped press enter to end") 
Input();

soundRec\Free()

PrintN("free") 

Input();

CloseConsole()