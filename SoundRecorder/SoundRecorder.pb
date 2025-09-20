;Test of miniaudio records to wav file and playbacks live 
;note it buffers to memory, then saves to wave at StopSoundRecorder  

;Records from default input to default output 

;*This requires that you have a full gcc toolchain eg mingw64 windows with env paths set to find #include <stdio.h> ... 
;add your gcc include paths to your PATH environment variable  
;eg 
;C:\mingw64\lib\gcc\x86_64-w64-mingw32\13.2.0\include\ 
;C:\mingw64\x86_64-w64-mingw32\include

;Download the header and adjust the #include path to suit 
;https://atomicwebserver.com/miniaudio_11_23.h

HeaderSection 
 
#include "E:\andrews\pbstuff\miniaudio\miniaudio_11_23.h"; 

EndHeaderSection 

ImportC "miniaudio.lib" : EndImport 

#ma_format_u8      = 1
#ma_format_s16     = 2     
#ma_format_s24     = 3     
#ma_format_s32     = 4
#ma_format_f32     = 5

Structure RIFFStructure
  Riff.a[4]
  Length.l
  Wave.a[4]
EndStructure

Structure fmtStructure
  fmt.a[4]
  Length.l
  Format.u
  Channels.u
  SampleRate.l
  BytesPerSecond.l
  BlockAlign.u
  BitsPerSample.u
EndStructure

Structure dataStructure
  Signature.a[4]
  Length.l
EndStructure

Structure nativeDataFormats
   format.i;       /* Sample format. If set to 0, all sample formats are supported. */
   channels.l;     /* If set to 0, all channels are supported. */
   sampleRate.l;   /* If set to 0, all sample rates are supported. */
   flags.l;        /* A combination of MA_DATA_FORMAT_FLAG_* flags. */
EndStructure 
  
Structure devices
  *device
  id.i 
  isDefault.i
  name.s
  nativeDataFormatCount.l
  format.nativeDataFormats[64] 
EndStructure   

Structure cSoundRec 
  *EnumDevices
  *NextDevice
  *IsDefault
  *SetFile
  *Config
  *Monitor
  *Start
  *Stop
  *Free
EndStructure 

Prototype EffectsCB(*input,numframes,time)

Structure SoundRec 
  *vt.cSoundRec
  device.i
  *WAVBuffer
  bRecord.i 
  *pbc 
  file.s 
  List Effects.i()
  Map CaptureDevices.devices(0)  
  Map PlayBackDevices.devices(0) 
EndStructure   

Procedure.i ResetSoundRecorder(*sound.SoundRec) 
  
  Protected.i Result, HeaderSize, DataSize
  Protected *RiffPtr.RIFFStructure, *fmtPtr.fmtStructure, *dataPtr.dataStructure, *audioPtr.word
    
  If *sound\WAVBuffer <> 0 
    FreeMemory(*sound\WAVBuffer) 
  EndIf   
  
  HeaderSize = SizeOf(RIFFStructure)
  HeaderSize + SizeOf(fmtStructure)
  HeaderSize + SizeOf(dataStructure)
  
  *sound\WAVBuffer = AllocateMemory(HeaderSize)
  
  If *sound\WAVBuffer 
    ProcedureReturn *sound\WAVBuffer 
  EndIf 
EndProcedure    

Procedure AppendSoundRecorder(*sound.SoundRec,*Data,len) 
  If *sound\WAVBuffer 
    pos = MemorySize(*sound\WAVBuffer) 
    *sound\WAVBuffer = ReAllocateMemory(*sound\WAVBuffer,pos+len) 
    CopyMemory(*data,*sound\WAVBuffer+pos,len) 
    ProcedureReturn *sound\WAVBuffer 
  EndIf 
EndProcedure 

Procedure StartSoundRecorder(SoundRec) 
  Protected *sound.SoundRec = SoundRec
  Protected *device = *sound\device 
  *sound\bRecord = 1  
  !ma_device_start(p_device);
  
EndProcedure  

Procedure MonitorSoundRecorder(SoundRec,*EffectsCB=0) 
  Protected *sound.SoundRec = SoundRec
  Protected *device = *sound\device 
  If *EffectsCB <> 0 
    AddElement(*sound\Effects()) 
    *sound\Effects() = *EffectsCB 
  EndIf 
  !ma_device_start(p_device);
  
EndProcedure 


Procedure StopSoundRecorder(SoundRec,samplerate=44100) 
  
  Protected.i Result, HeaderSize, DataSize,channels,format,depth  
  Protected *RiffPtr.RIFFStructure, *fmtPtr.fmtStructure, *dataPtr.dataStructure, *audioPtr.word
  Protected *sound.SoundRec = soundRec 
  Protected *device = *sound\device 
  
  *sound\bRecord = 0 
  !ma_device_stop(p_device);
  
  !ma_device *tpdevice = p_device; 
      
  If *sound\WAVBuffer 
    
    If *sound\file <> ""
      
      !v_format = tpdevice->capture.format;
      !v_channels = tpdevice->capture.channels; 
      
      HeaderSize = SizeOf(RIFFStructure)
      HeaderSize + SizeOf(fmtStructure)
      HeaderSize + SizeOf(dataStructure)
      
      DataSize = MemorySize(*sound\WAVBuffer) - (HeaderSize)
      
      *RiffPtr = *sound\WAVBuffer
      PokeS(@*RiffPtr\Riff, "RIFF", 4, #PB_Ascii|#PB_String_NoZero)
      *RiffPtr\Length = HeaderSize + DataSize - 8
      PokeS(@*RiffPtr\Wave, "WAVE", 4, #PB_Ascii|#PB_String_NoZero)
      
      *fmtPtr = *sound\WAVBuffer + SizeOf(RIFFStructure)
      PokeS(@*fmtPtr\fmt, "fmt ", 4, #PB_Ascii|#PB_String_NoZero)
      *fmtPtr\Length = SizeOf(fmtStructure) - 8
      If format = #ma_format_f32
        *fmtPtr\Format = 3
         depth = 32
      Else
        *fmtPtr\Format = 1
        Select format 
            Case #ma_format_u8 
              depth = 8   
            Case #ma_format_s16     
              depth = 16    
            Case #ma_format_s24   
              depth = 24   
            Case #ma_format_s32
              depth = 32 
        EndSelect        
      EndIf   
      
      *fmtPtr\Channels = channels 
      *fmtPtr\SampleRate = samplerate   
      *fmtPtr\BitsPerSample = depth           
      *fmtPtr\BlockAlign =  (depth>>3) * 2   
      *fmtPtr\BytesPerSecond = samplerate * (depth>>3) 
      
      *dataPtr = *sound\WAVBuffer + SizeOf(RIFFStructure) + SizeOf(fmtStructure)
      PokeS(@*dataPtr\Signature, "data", 4, #PB_Ascii|#PB_String_NoZero)
      *dataPtr\Length = DataSize
      
      fn = CreateFile(#PB_Any,*sound\file) 
      If fn 
        x = WriteData(fn,*sound\WAVBuffer,MemorySize(*sound\WAVBuffer)) 
        CloseFile(fn) 
      EndIf
      
    EndIf 
    
    FreeMemory(*sound\WAVBuffer)
    
  EndIf  
  
  ProcedureReturn x
  
EndProcedure

ProcedureC data_callback(*Device,*Output,*Input,frameCount)
  Protected amount,format,channels,*sound.SoundRec 
  Protected *fx.EffectsCB 
  If frameCount  
    !ma_device *pdevice = p_device; 
    !v_amount = v_framecount * ma_get_bytes_per_frame(pdevice->capture.format, pdevice->capture.channels);
    !p_sound = pdevice->pUserData; 
    !v_format = pdevice->capture.format; 
    !v_channels = pdevice->capture.channels;
    If amount <> 0  
      If (*input And *output)  
        If amount > 4 
        ForEach *sound\Effects() 
          *fx = *sound\Effects() 
          *fx(*input,frameCount,ElapsedMilliseconds()/1000.0)
        Next  
        EndIf 
        CopyMemory(*input,*Output,amount)
      EndIf 
      If (*input And *sound\bRecord)
        If *sound\WAVBuffer = 0 
          *sound\WAVBuffer = ResetSoundRecorder(*sound)
        EndIf   
        If *sound\WAVBuffer 
          *sound\WAVBuffer = AppendSoundRecorder(*sound,*input,amount)
        EndIf 
      EndIf   
    EndIf
  EndIf 
EndProcedure 

Procedure EnumSoundDevices(*sound.SoundRec) 
  Protected ind,temp,ta  
  !ma_context context;
  !ma_device_info *pCaptureInfos;// = (ma_device_info *) malloc(sizeof(ma_device_info));
  !ma_device_info *pPlaybackInfos;// = (ma_device_info *) malloc(sizeof(ma_device_info));
  
  !if (ma_context_init(NULL, 0, NULL, &context) == MA_SUCCESS) {
    !ma_uint32 captureCount; 
    !ma_uint32 playCount;
    !if (ma_context_get_devices(&context,&pPlaybackInfos,&playCount,&pCaptureInfos,&captureCount) == MA_SUCCESS) {
        
     !for (ma_uint32 iDevice = 0; iDevice < captureCount; iDevice += 1) {
       !v_ind = iDevice;  
       !v_temp = pCaptureInfos[iDevice].name;
       AddMapElement(*sound\CaptureDevices(),PeekS(temp,-1,#PB_Ascii))       
       !v_temp = &pCaptureInfos[iDevice];
       *sound\CaptureDevices()\device = temp 
       !v_temp = &pCaptureInfos[iDevice].id; 
       *sound\CaptureDevices()\id = temp 
       !v_temp = pCaptureInfos[iDevice].name;
       *sound\CaptureDevices()\name = PeekS(temp,-1,#PB_Ascii)
       !v_temp = pCaptureInfos[iDevice].isDefault;
       *sound\CaptureDevices()\isDefault = temp 
       !v_temp = pCaptureInfos[iDevice].nativeDataFormatCount; 
       *sound\CaptureDevices()\nativeDataFormatCount=temp 
       
       !for (ma_uint32 a = 0; a < pCaptureInfos[iDevice].nativeDataFormatCount; a += 1) { 
          !v_ta = a;
          !v_temp = pCaptureInfos[iDevice].nativeDataFormats[a].format;  
          *sound\CaptureDevices()\format[ta]\format = temp 
          !v_temp = pCaptureInfos[iDevice].nativeDataFormats[a].channels;  
          *sound\CaptureDevices()\format[ta]\channels = temp 
          !v_temp = pCaptureInfos[iDevice].nativeDataFormats[a].sampleRate;  
          *sound\CaptureDevices()\format[ta]\sampleRate = temp 
          !}
          
              
     !}
     !for (ma_uint32 iDevice = 0; iDevice < playCount; iDevice += 1) {
       !v_ind = iDevice;  
        !v_temp = pPlaybackInfos[iDevice].name; 
       AddMapElement(*sound\PlayBackDevices(),PeekS(temp,-1,#PB_Ascii))
       
       !v_temp = &pPlaybackInfos[iDevice];
       *sound\PlayBackDevices()\device = temp 
       !v_temp = &pPlaybackInfos[iDevice].id;
       *sound\PlayBackDevices()\id = temp 
       !v_temp = pPlaybackInfos[iDevice].name; 
       *sound\PlayBackDevices()\name = PeekS(temp,-1,#PB_Ascii)
        !v_temp = pPlaybackInfos[iDevice].isDefault;
       *sound\PlayBackDevices()\isDefault = temp 
       
       !v_temp = pPlaybackInfos[iDevice].nativeDataFormatCount; 
       *sound\PlayBackDevices()\nativeDataFormatCount=temp 
       
       !for (ma_uint32 a = 0; a < pPlaybackInfos[iDevice].nativeDataFormatCount; a += 1) { 
          !v_ta = a;
          !v_temp = pPlaybackInfos[iDevice].nativeDataFormats[a].format;  
          *sound\PlayBackDevices()\format[ta]\format = temp 
          !v_temp = pPlaybackInfos[iDevice].nativeDataFormats[a].channels;  
          *sound\PlayBackDevices()\format[ta]\channels = temp 
          !v_temp = pPlaybackInfos[iDevice].nativeDataFormats[a].sampleRate;  
          *sound\PlayBackDevices()\format[ta]\sampleRate = temp 
          !}              
     !}
    !}
  !}
  
EndProcedure 

#ma_device_type_capture =2   ;records from an input microphone or stereo mix
#ma_device_type_duplex = 3   ;records from input sources mic or stereo mix and plays back     
#ma_device_type_loopback = 4 ;windows only captures what's currently playing  

Procedure ConfigSoundRecorder(soundRec,input.s,format=#ma_format_s16,sampleRate=44100,mode=#ma_device_type_capture) 
  Protected dev,result,iinput 
  Protected *sound.SoundRec = soundRec  
  
  If FindMapElement(*sound\CaptureDevices(),input) 
    iinput = *sound\CaptureDevices()\id 
  EndIf 
  
  !ma_device_config deviceConfig;
  !ma_device *device = (ma_device*) malloc(sizeof(ma_device));
  !device->pUserData = p_sound;

Select mode 
   Case #ma_device_type_capture 
     !deviceConfig = ma_device_config_init(ma_device_type_capture);
     !deviceConfig.sampleRate = v_samplerate;
     !deviceConfig.capture.pDeviceID  = v_iinput;  //NULL;
     !deviceConfig.capture.format     = v_format;
     !deviceConfig.capture.channels   = 2;
     !deviceConfig.capture.shareMode  = ma_share_mode_shared;
     !deviceConfig.dataCallback       = &f_data_callback; 
     !deviceConfig.pUserData = p_sound;
   Case #ma_device_type_loopback 
     CompilerIf #PB_Compiler_OS = #PB_OS_Windows 
     !deviceConfig = ma_device_config_init(ma_device_type_loopback);
     !deviceConfig.sampleRate = v_samplerate;
     !deviceConfig.capture.pDeviceID  = NULL;
     !deviceConfig.capture.format     = v_format;
     !deviceConfig.capture.channels   = 2;
     !deviceConfig.capture.shareMode  = ma_share_mode_shared;
     !deviceConfig.dataCallback       = &f_data_callback;
     !deviceConfig.pUserData = p_sound;
   CompilerElse 
     CompilerError "loopback only supported on windows"  
   CompilerEndIf 
   Case #ma_device_type_duplex 
     !deviceConfig = ma_device_config_init(ma_device_type_duplex);
     !deviceConfig.sampleRate = v_samplerate;
     !deviceConfig.capture.pDeviceID  = v_iinput;  //NULL;
     !deviceConfig.capture.format     = v_format;
     !deviceConfig.capture.channels   = 2;
     !deviceConfig.capture.shareMode  = ma_share_mode_shared;
     !deviceConfig.playback.pDeviceID = NULL;
     !deviceConfig.playback.format    = v_format; //ma_format_s16;
     !deviceConfig.playback.channels  = 2;
     !deviceConfig.dataCallback       = &f_data_callback; 
     !deviceConfig.pUserData = p_sound;
     
EndSelect       

!v_result = ma_device_init(NULL, &deviceConfig, &*device);

If result <> 0
  MessageRequester("error","failed to config")
  ProcedureReturn 0
EndIf  

!v_dev = device; 

*sound\device = dev 

ProcedureReturn #True  

EndProcedure 

Procedure FreeSoundRecorder(sound) 
  Protected *sound.SoundRec = sound 
  recorder = *sound\device
  !ma_device_uninit(v_recorder);  
  !free(v_recorder); 
  FreeStructure(*sound) 
EndProcedure  

Procedure EnumSoundCaptureDevices(sound)
  Protected *sound.SoundRec = sound 
  ResetMap(*sound\CaptureDevices()) 
EndProcedure  

Procedure NextSoundCaptureDevice(sound) 
  Protected *sound.SoundRec = sound 
  If NextMapElement(*sound\CaptureDevices())
    ProcedureReturn @*sound\CaptureDevices()\name  
  EndIf   
EndProcedure   

Procedure IsDefault(sound,device.s) 
  Protected *sound.SoundRec = sound  
  If FindMapElement(*sound\CaptureDevices(),device) 
    ProcedureReturn *sound\CaptureDevices()\isDefault 
  EndIf  
EndProcedure   

Procedure SetRecordingFile(sound,filename.s) 
  Protected *sound.SoundRec = sound   
  *sound\file = filename 
EndProcedure  

ProcedureDLL InitSoundRecorder() 
  *sound.SoundRec = AllocateStructure(SoundRec)  
  *sound\vt = AllocateMemory(SizeOf(cSoundRec))
  *sound\vt\Config = @ConfigSoundRecorder()
  *sound\vt\Free = @FreeSoundRecorder() 
  *sound\vt\EnumDevices = @EnumSoundCaptureDevices() 
  *sound\vt\NextDevice = @NextSoundCaptureDevice() 
  *sound\vt\IsDefault = @IsDefault() 
  *sound\vt\SetFile = @SetRecordingFile()
  *sound\vt\Monitor = @MonitorSoundRecorder() 
  *sound\vt\Start = @StartSoundRecorder()
  *sound\vt\Stop = @StopSoundRecorder() 
  *sound\pbc = @data_callback() 
  EnumSoundDevices(*sound)  
  ProcedureReturn *sound 
EndProcedure   

#TestSound = 1

CompilerIf #TestSound 
  
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
  
CompilerEndIf  