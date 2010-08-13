package com.craniumisajar.inputs {

  import spark.components.Application;
  import mx.core.UIComponent;
  import mx.controls.Alert;
  import flash.events.*;
  import mx.events.*;
  import flash.system.Security;
  import flash.system.SecurityPanel;
  import flash.external.ExternalInterface;

  import flash.net.NetConnection;
  import flash.net.NetStream;

  import flash.media.Camera;
  import flash.media.Microphone;
  import flash.media.Video;

  public class WebcamPublisher extends Application {

    private var rtmp_app_url:String;
    private var rtmp_stream_name:String;
    private var cam_width:int = 320;
    private var cam_height:int = 240;
    private var cam_rate:int = 15;
    private var cam_bandwidth:int = 0;
    private var cam_quality:int = 90;
    private var vid_scale:int = 1;
    private var mic_rate:int = 22000;
    private var mic_gain:int = 85;
    private var mic_silence_level:int = 1;
    private var connection:NetConnection;
    private var stream:NetStream;
    private var cam:Camera;
    private var mic:Microphone;
    private var vid:Video;
    private var vid_holder:UIComponent = new UIComponent();
    private var flashvars:Object;

    public function WebcamPublisher() {
      super();
      addEventListener( FlexEvent.APPLICATION_COMPLETE, initializeWebcamPublisher );
    }

    private function initializeWebcamPublisher(event:Event):void {
      log( "initializing" );
      initializeRtmpSettings();
    }

    private function initializeRtmpSettings():void {
      rtmp_app_url = getSetting('rtmp_app_url');
      rtmp_stream_name = getSetting('rtmp_stream_name');
      if (rtmp_app_url != '' && rtmp_stream_name != '') {
        initializeNetConnection(); // this sets connection and stream vars
      } else {
        log("Must set flashvars for <rtmp_app_url> and <rtmp_stream_name>", 
            true);
      }
    }

    private function getSetting(setting:String, fallback:String=''):String {
      if ( parameters[setting] != null ) {
        return parameters[setting];
      } else {
        return fallback;
      } 
    }
    
    // External interface - START
    private function initializeExternalInterface():void {
      if (!ExternalInterface.available) {
        log("Cannot call external javascripts!", true);
      } else {
        try {
          Security.allowDomain('*'); // prob not great
          ExternalInterface.call("onFlashAppCreationComplete");
          ExternalInterface.addCallback('start_recording', startRecording);
          ExternalInterface.addCallback('stop_recording', stopRecording);
        } catch (error:Error) {
          log('error occured in external interface: ' + error, true);
        }
      }
    }

    private function startRecording():void {
      log('starting recording: ' + rtmp_stream_name);
      stream.attachCamera(cam);
      stream.attachAudio(mic);
      stream.publish(rtmp_stream_name, 'record');
    }

    private function stopRecording():void {
      log('stopping recording: ' + rtmp_stream_name);
      stream.attachCamera(null);
      stream.attachAudio(null);
      stream.close();
    }
    // External interface - END

    //  NetConnection and related handlers - START
    private function initializeNetConnection():void {
      connection = new NetConnection();
      connection.addEventListener( NetStatusEvent.NET_STATUS, netConnectionNetStatusHandler );
      connection.addEventListener( SecurityErrorEvent.SECURITY_ERROR, netConnectionEventHandler );
      connection.addEventListener( AsyncErrorEvent.ASYNC_ERROR, netConnectionEventHandler );
      connection.addEventListener( IOErrorEvent.IO_ERROR, netConnectionEventHandler );
      connection.connect( rtmp_app_url );
    }

    private function netConnectionNetStatusHandler(event:NetStatusEvent):void {
      switch (event.info.code) {
        case "NetConnection.Connect.Success":
          log("connected to remote application");
          initializeNetStream();
          if (connection && stream) {
            initializeCamera();
            initializeMicrophone();
            initializeVideo();
            attachCamToVid();
            initializeExternalInterface();
          } else {
            log('Connection to video server failed!', true);
          }
          break;
        default:
          log("unhandled NetConnection NetStatusEvent: " + event.info.code);
          log("   " + event);
          break;  
      }
    }    

    private function netConnectionEventHandler(event:Event):void {
      log("Net Connection Event: " + event);
    }
    //  NetConnection and related handlers - END

    //  NetStream and related handlers - START
    private function initializeNetStream():void {
      stream = new NetStream(connection);
      stream.addEventListener( NetStatusEvent.NET_STATUS, netStreamNetStatusHandler );
      stream.addEventListener( AsyncErrorEvent.ASYNC_ERROR, netStreamEventHandler );
      stream.addEventListener( IOErrorEvent.IO_ERROR, netStreamEventHandler );
    }

    private function netStreamNetStatusHandler(event:NetStatusEvent):void {
      switch (event.info.code) {
        case "NetStream.Connect.Success":
          log("connected to remote stream service");
          break;
        default:
          log("unhandled NetStream NetStatusEvent: " + event.info.code);
          log("   " + event);
          break;  
      }
    }    

    private function netStreamEventHandler(event:Event):void {
      log("Net Stream Event: " + event);
    }
    //  NetStream and related handlers - END

    // Camera and related handlers - START
    private function initializeCamera():void {
      cam = Camera.getCamera();
      if (!cam) {
        log('no camera found');
      } else if (cam.muted) {
        log('muted camera found');
        showSecurityPanel();
      } else {
        cam.setMode(cam_width, cam_height, cam_rate, false);
        cam.setQuality(cam_bandwidth, cam_quality);
        cam.addEventListener(ActivityEvent.ACTIVITY, cameraActivityHandler);
        log('camera initialized');
      }
    }

    private function cameraActivityHandler(event:ActivityEvent):void {
      log("camera activity: " + event);
    }
    // Camera and related handlers - END

    // Microphone and related handlers - START
    private function initializeMicrophone():void {
      mic = Microphone.getMicrophone();
      if (!mic) {
        log('no mic found');
      } else if (mic.muted) {
        log('muted mic found');
        showSecurityPanel();
      } else {
        mic.rate = mic_rate;
        mic.gain = mic_gain;
        mic.setSilenceLevel(mic_silence_level);
        mic.addEventListener(ActivityEvent.ACTIVITY, microphoneActivityHandler);
        log('mic initialized');
      }
    }

    private function microphoneActivityHandler(event:ActivityEvent):void {
      log("microphone activity: " + event);
    }
    // Microphone and related handlers - END

    // Video and related handlers - START
    private function initializeVideo():void {
      vid = new Video(cam_width * vid_scale, cam_height * vid_scale);
      vid.smoothing = true;
      addElement(vid_holder);
      log("video initialized");
    }

    private function detachAllFromVid():void {
      vid.attachCamera(null);
      vid.attachNetStream(null);
      log('all sources detached from video');
    }

    private function attachCamToVid():void {
      detachAllFromVid();
      vid.attachCamera(cam);
      vid_holder.addChild(vid);
      log("camera attached to video");
    }

    private function attachStreamToVid():void {
      detachAllFromVid();
      vid.attachNetStream(stream);
      vid_holder.addChild(vid);
      log("stream attached to video");
    }
    // Video and related handlers - END

    // Security functions
    private function showSecurityPanel():void {
      log('showing security panel');
      Security.showSettings(SecurityPanel.PRIVACY);  
    }

    // Utilities
    private function log(entry:String, alert:Boolean = false):void {
      trace( "WebcamInput: " + entry );
      if (alert) {
        Alert.show(entry);
      }
    }
  }
}
