import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class CallScreen extends StatefulWidget {
  final String channelName;
  final String token;
  final bool isVideo;
  final String callerName;

  const CallScreen({
    super.key,
    required this.channelName,
    required this.token,
    required this.isVideo,
    required this.callerName,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late RtcEngine _engine;
  bool _localUserJoined = false;
  bool _remoteUserJoined = false;
  bool _muted = false;
  bool _speakerOn = true;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    await [Permission.microphone, Permission.camera].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: '1987a99a12844a8bab725a946a73be15',
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          setState(() => _localUserJoined = true);
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          setState(() => _remoteUserJoined = true);
        },
        onUserOffline: (connection, remoteUid, reason) {
          setState(() => _remoteUserJoined = false);
          Navigator.pop(context);
        },
      ),
    );

    if (widget.isVideo) {
      await _engine.enableVideo();
    }

    await _engine.joinChannel(
      token: widget.token,
      channelId: widget.channelName,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
      uid: 0,
    );
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _engine.muteLocalAudioStream(_muted);
  }

  void _toggleSpeaker() {
    setState(() => _speakerOn = !_speakerOn);
    _engine.setEnableSpeakerphone(_speakerOn);
  }

  void _endCall() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (widget.isVideo && _remoteUserJoined)
              AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: _engine,
                  canvas: const VideoCanvas(uid: 0),
                  connection: RtcConnection(channelId: widget.channelName),
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      child: Text(widget.callerName[0].toUpperCase()),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.callerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                    if (!_remoteUserJoined)
                      const Text(
                        'Aranıyor...',
                        style: TextStyle(color: Colors.white70),
                      ),
                  ],
                ),
              ),
            if (widget.isVideo && _localUserJoined)
              Positioned(
                top: 20,
                right: 20,
                child: SizedBox(
                  width: 120,
                  height: 160,
                  child: AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _engine,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    onPressed: _toggleMute,
                    backgroundColor: _muted ? Colors.red : Colors.grey[800],
                    child: Icon(_muted ? Icons.mic_off : Icons.mic),
                  ),
                  FloatingActionButton(
                    onPressed: _endCall,
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.call_end),
                  ),
                  FloatingActionButton(
                    onPressed: _toggleSpeaker,
                    backgroundColor: Colors.grey[800],
                    child: Icon(_speakerOn ? Icons.volume_up : Icons.volume_off),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}