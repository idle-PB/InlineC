#ma_format_u8      = 1
#ma_format_s16     = 2     
#ma_format_s24     = 3     
#ma_format_s32     = 4
#ma_format_f32     = 5

#ma_device_type_capture =2   ;records from an input microphone or stereo mix
#ma_device_type_duplex = 3   ;records from input sources mic or stereo mix and plays back     
#ma_device_type_loopback = 4 ;windows only captures what's currently playing  

InitSound()

Interface iSoundRecorder 
  EnumDevices()
  NextDevice() 
  IsDefault(device.s)
  SetFile(filename.s)
  Config(device.s,format=#ma_format_s16,sampleRate=44100,mode=#ma_device_type_capture) 
  Start()
  Stop(samplerate=44100)
  Free()
EndInterface   

Import "SoundRecorder.lib" 
  InitSoundRecorder() 
EndImport   

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

;soundRec\Config("",#ma_format_s16,44100,#ma_device_type_duplex)     ;record on default input and playback 
;soundRec\Config(device,#ma_format_s16,44100)                       ;record on selected input 
soundRec\Config("",#ma_format_s16,44100,#ma_device_type_loopback)  ;record on whats being currently played on speaker

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

CloseConsole()
