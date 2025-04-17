import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:translator/translator.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http_parser/http_parser.dart' as http_parser;

class AiTutorPage extends StatefulWidget {
  const AiTutorPage({super.key});

  @override
  State<AiTutorPage> createState() => _AiTutorPageState();
}

class _AiTutorPageState extends State<AiTutorPage>
    with TickerProviderStateMixin {
  late final GenerativeModel model;
  bool isLoading = false;
  bool isRecording = false;
  bool showPlayer = false;
  String? audioPath;

  // API keys - Consider moving these to a secure location or environment variables
  final apiKey = 'AIzaSyBys20MmSX9urBP7mTgx2sS-Jho_hJt4NQ';
  final openRouterApiKey =
      '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';
  final sarvamApiKey = '70beb2ed-3731-47a8-8bd0-683063260d38';

  late AnimationController _bounceController;
  late final Record record;

  final FlutterTts flutterTts = FlutterTts();
  final translator = GoogleTranslator();
  final TextRecognizer _textRecognizer = GoogleMlKit.vision.textRecognizer();
  String selectedLanguage = 'en-IN';
  int userScore = 0;

  bool isSpeaking = false;

  // Player state variables
  late AudioPlayer player = AudioPlayer();
  PlayerState? _playerState;
  Duration? _duration;
  Duration? _position;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<void>? _playerCompleteSubscription;
  StreamSubscription<PlayerState>? _playerStateChangeSubscription;

  bool get _isPlaying => _playerState == PlayerState.playing;
  bool get _isPaused => _playerState == PlayerState.paused;
  String get _durationText => _duration?.toString().split('.').first ?? '';
  String get _positionText => _position?.toString().split('.').first ?? '';

  final Map<String, String> indianLanguages = {
    'en-IN': 'English (India)',
    'hi-IN': 'Hindi',
    'bn-IN': 'Bengali',
    'kn-IN': 'Kannada',
    'ml-IN': 'Malayalam',
    'mr-IN': 'Marathi',
    'od-IN': 'Odia',
    'pa-IN': 'Punjabi',
    'ta-IN': 'Tamil',
    'te-IN': 'Telugu',
    'gu-IN': 'Gujarati'
  };

  List<ChatMessage> messages = [];
  ChatUser currentUser = ChatUser(id: "0", firstName: "Student");
  ChatUser aiUser = ChatUser(
    id: "1",
    firstName: "Vidyasagar",
    profileImage:
    "https://cdn2.vectorstock.com/i/1000x1000/64/71/female-teacher-avatar-educacion-and-school-vector-38156471.jpg",
  );

  @override
  void initState() {
    super.initState();

    // Initialize Gemini model
    try {
      model = GenerativeModel(
        model: 'gemini-1.5-flash-latest',
        apiKey: apiKey,
      );
    } catch (e) {
      debugPrint('Error initializing Gemini model: $e');
      // Show an error message to the user if model initialization fails
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to initialize AI model: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });
    }

    _initTts();
    record = Record();
    _initRecorder();
    showPlayer = false;
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Add initial welcome message
    messages.add(
      ChatMessage(
        user: aiUser,
        createdAt: DateTime.now(),
        text:
        "Namaste! I am Vidyasagar, your AI education guide. I can help you learn new topics through text, images and suggest relevant educational YouTube videos. How may I assist you today?",
      ),
    );

    // Initialize audio player
    player = AudioPlayer();
    player.setReleaseMode(ReleaseMode.stop);
    _initStreams();
  }

  Future<void> _initRecorder() async {
    try {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw 'Microphone permission not granted';
      }
      await record.hasPermission();
    } catch (e) {
      debugPrint('Error initializing recorder: $e');
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    record.dispose();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateChangeSubscription?.cancel();
    player.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  void _initStreams() {
    _durationSubscription = player.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    _positionSubscription = player.onPositionChanged.listen(
          (p) => setState(() => _position = p),
    );

    _playerCompleteSubscription = player.onPlayerComplete.listen((event) {
      setState(() {
        _playerState = PlayerState.stopped;
        _position = Duration.zero;
      });
    });

    _playerStateChangeSubscription =
        player.onPlayerStateChanged.listen((state) {
          setState(() {
            _playerState = state;
          });
        });
  }

  Future<void> _play() async {
    try {
      if (audioPath != null) {
        await player.play(DeviceFileSource(audioPath!));
        setState(() => _playerState = PlayerState.playing);
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  Future<void> _pause() async {
    try {
      await player.pause();
      setState(() => _playerState = PlayerState.paused);
    } catch (e) {
      debugPrint('Error pausing audio: $e');
    }
  }

  Future<void> _stop() async {
    try {
      await player.stop();
      setState(() {
        _playerState = PlayerState.stopped;
        _position = Duration.zero;
      });
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  Future<void> _initTts() async {
    try {
      await flutterTts.setLanguage(selectedLanguage);
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.setVolume(1.0);
      await flutterTts.setPitch(1.0);

      flutterTts.setStartHandler(() {
        setState(() {
          isSpeaking = true;
        });
      });

      flutterTts.setCompletionHandler(() {
        setState(() {
          isSpeaking = false;
        });
      });

      flutterTts.setErrorHandler((msg) {
        setState(() {
          isSpeaking = false;
        });
      });
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
    }
  }

  Future<void> _startRecording() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final path =
          '${appDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.wav';

      if (await record.hasPermission()) {
        await record.start(
            path: path,
            encoder: AudioEncoder.wav,
            bitRate: 128000,
            samplingRate: 44100,
            numChannels: 2);

        setState(() {
          isRecording = true;
          audioPath = path;
        });
        debugPrint('Recording at path: $path');
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
      _showErrorDialog('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await record.stop();
      setState(() {
        isRecording = false;
        showPlayer = true;
      });
      debugPrint('Stopped recording at path: $path');

      if (path != null) {
        setState(() {
          audioPath = path;
        });

        if (!mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Processing audio..."),
                ],
              ),
            );
          },
        );

        String languageCode = selectedLanguage.split('-')[0].toLowerCase();
        if (!['hi', 'bn', 'kn', 'ml', 'mr', 'od', 'pa', 'ta', 'te', 'gu', 'en']
            .contains(languageCode)) {
          if (!mounted) return;
          Navigator.pop(context); // Dismiss the processing dialog
          _showErrorDialog('Selected language is not supported by Sarvam API');
          return;
        }

        // If the language is English, still use en-IN for Sarvam API
        String sarvamLanguageCode = '$languageCode-IN';

        try {
          var file = await http.MultipartFile.fromPath(
            'file',
            path,
            contentType: http_parser.MediaType.parse('audio/wav'),
          );

          var request = http.MultipartRequest(
              'POST', Uri.parse('https://api.sarvam.ai/speech-to-text'))
            ..headers.addAll({
              'api-subscription-key': sarvamApiKey,
            })
            ..files.add(file)
            ..fields['model'] = 'saarika:v1'
            ..fields['language_code'] = sarvamLanguageCode
            ..fields['with_timestamps'] = 'true';

          var response = await request.send();
          var responseData = await response.stream.bytesToString();
          var jsonResponse = jsonDecode(responseData);

          debugPrint('Sarvam API Response: $jsonResponse');

          if (!mounted) return;
          Navigator.pop(context); // Dismiss the processing dialog

          if (response.statusCode != 200) {
            _showErrorDialog(
                'API Error: ${jsonResponse['error']?['message'] ?? 'Unknown error'}');
            return;
          }

          if (!mounted) return;
          await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Result"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      jsonResponse['transcript'] ?? 'No transcript found',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    child: const Text("Cancel"),
                    onPressed: () => Navigator.pop(context),
                  ),
                  TextButton(
                    child: const Text("Send"),
                    onPressed: () {
                      if (jsonResponse['transcript'] != null) {
                        ChatMessage chatMessage = ChatMessage(
                          user: currentUser,
                          createdAt: DateTime.now(),
                          text: jsonResponse['transcript'],
                        );
                        _sendMessage(chatMessage);
                      }
                      Navigator.pop(context);
                    },
                  ),
                ],
              );
            },
          );
        } catch (e) {
          if (!mounted) return;
          Navigator.pop(context); // Dismiss the processing dialog
          _showErrorDialog('Error processing audio: $e');
        }
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      _showErrorDialog('Failed to stop recording: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue[100],
        centerTitle: true,
        title: Text(
          "Vidyasagar - AI Tutor",
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        leading: Tooltip(
          message: "Your learning points",
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: const Offset(0, -0.1),
            ).animate(_bounceController),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Score\n$userScore',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        actions: [
          Tooltip(
            message: "Change language",
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.language, color: Colors.black87),
              onSelected: (String value) {
                setState(() {
                  selectedLanguage = value;
                  flutterTts.setLanguage(value);
                });
              },
              itemBuilder: (BuildContext context) => indianLanguages.entries
                  .map(
                    (entry) => PopupMenuItem<String>(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    style: GoogleFonts.montserrat(),
                  ),
                ),
              )
                  .toList(),
            ),
          ),
        ],
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue[100]!, Colors.white],
        ),
      ),
      child: Column(
        children: [
          if (isLoading)
            const LinearProgressIndicator(),
          if (showPlayer)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        key: const Key('play_button'),
                        onPressed: _isPlaying ? null : _play,
                        iconSize: 48.0,
                        icon: const Icon(Icons.play_arrow),
                        color: Theme.of(context).primaryColor,
                      ),
                      IconButton(
                        key: const Key('pause_button'),
                        onPressed: _isPlaying ? _pause : null,
                        iconSize: 48.0,
                        icon: const Icon(Icons.pause),
                        color: Theme.of(context).primaryColor,
                      ),
                      IconButton(
                        key: const Key('stop_button'),
                        onPressed: _isPlaying || _isPaused ? _stop : null,
                        iconSize: 48.0,
                        icon: const Icon(Icons.stop),
                        color: Theme.of(context).primaryColor,
                      ),
                      IconButton(
                        key: const Key('delete_button'),
                        onPressed: () {
                          setState(() => showPlayer = false);
                        },
                        iconSize: 48.0,
                        icon: const Icon(Icons.delete),
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                  Slider(
                    activeColor: Theme.of(context).primaryColor,
                    onChanged: (value) {
                      final duration = _duration;
                      if (duration == null) {
                        return;
                      }
                      final position = value * duration.inMilliseconds;
                      player.seek(Duration(milliseconds: position.round()));
                    },
                    value: (_position != null &&
                        _duration != null &&
                        _position!.inMilliseconds > 0 &&
                        _position!.inMilliseconds <
                            _duration!.inMilliseconds)
                        ? _position!.inMilliseconds / _duration!.inMilliseconds
                        : 0.0,
                  ),
                  Text(
                    _position != null
                        ? '$_positionText / $_durationText'
                        : _duration != null
                        ? _durationText
                        : '',
                    style: const TextStyle(fontSize: 16.0),
                  ),
                ],
              ),
            ),
          Expanded(
            child: DashChat(
              messageOptions: MessageOptions(
                containerColor: Colors.blue[600]!,
                currentUserContainerColor: Colors.green[600]!,
                textColor: Colors.white,
                showTime: true,
                messagePadding: const EdgeInsets.all(12),
                borderRadius: 16,
              ),
              inputOptions: InputOptions(
                inputTextStyle: GoogleFonts.montserrat(),
                inputDecoration: InputDecoration(
                  hintText: "Ask me anything...",
                  hintStyle: GoogleFonts.montserrat(color: Colors.grey),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                trailing: [
                  Tooltip(
                    message: "Upload image",
                    child: IconButton(
                      onPressed: _sendMediaMessage,
                      icon: const Icon(Icons.image, color: Colors.blue),
                    ),
                  ),
                  Tooltip(
                    message: isRecording ? "Stop recording" : "Start recording",
                    child: IconButton(
                      onPressed: isRecording ? _stopRecording : _startRecording,
                      icon: Icon(
                        isRecording ? Icons.stop : Icons.mic,
                        color: isRecording ? Colors.red : Colors.blue,
                      ),
                    ),
                  ),
                  Tooltip(
                    message: isSpeaking ? "Stop speaking" : "Speak message",
                    child: IconButton(
                      onPressed: () {
                        if (isSpeaking) {
                          flutterTts.stop();
                          setState(() {
                            isSpeaking = false;
                          });
                        } else if (messages.isNotEmpty) {
                          flutterTts.speak(messages.first.text);
                          setState(() {
                            isSpeaking = true;
                          });
                        }
                      },
                      icon: Icon(
                        isSpeaking ? Icons.stop : Icons.volume_up,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
              currentUser: currentUser,
              onSend: _sendMessage,
              messages: messages,
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(ChatMessage chatMessage) async {
    if (isLoading) return;

    setState(() {
      messages = [chatMessage, ...messages];
      isLoading = true;
    });

    try {
      String translatedText = chatMessage.text;

      // Translate the message to English if needed
      if (selectedLanguage != 'en-IN') {
        try {
          final translation = await translator.translate(
            chatMessage.text,
            from: selectedLanguage.split('-')[0],
            to: 'en',
          );
          translatedText = translation.text;
          debugPrint('Translated text: $translatedText');
        } catch (e) {
          debugPrint('Translation error: $e');
          // Continue with original text if translation fails
        }
      }

      String geminiResponse = '';

      // Handle message based on whether it has media (image) attached
      if (chatMessage.medias?.isNotEmpty ?? false) {
        try {
          final bytes = await File(chatMessage.medias![0].url).readAsBytes();
          final inputImage = InputImage.fromFilePath(chatMessage.medias![0].url);
          final recognizedText = await _textRecognizer.processImage(inputImage);

          final prompt = 'Analyze this image and provide a detailed explanation: $translatedText\n\nExtracted text: ${recognizedText.text}';
          debugPrint('Image prompt: $prompt');

          final content = Content.multi([
            TextPart(prompt),
            DataPart('image/jpeg', bytes),
          ]);

          // FIX: Wrap content in a list to match the expected Iterable<Content> type
          final geminiResult = await model.generateContent([content]);
          geminiResponse = geminiResult.text ?? 'I couldn\'t generate a response for this image.';
        } catch (e) {
          debugPrint('Error processing image: $e');
          geminiResponse = 'I had trouble analyzing this image. Could you try another one or describe what you\'re looking for?';
        }
      } else {
        try {
          // Text-only query
          final content = Content.text(translatedText);
          // FIX: Wrap content in a list to match the expected Iterable<Content> type
          final geminiResult = await model.generateContent([content]);
          geminiResponse = geminiResult.text ?? 'I couldn\'t generate a response to your question.';
        } catch (e) {
          debugPrint('Error getting Gemini response: $e');
          geminiResponse = 'I had trouble processing your question. Could you try rephrasing it?';
        }
      }

      String finalResponse = geminiResponse;

      // Try to get recommendations from OpenRouter
      try {
        final openRouterResponse = await http.post(
          Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $openRouterApiKey',
          },
          body: jsonEncode({
            'model': 'perplexity/llama-3.1-sonar-huge-128k-online',
            'messages': [
              {
                'role': 'user',
                'content':
                'Based on this educational content, suggest relevant YouTube videos and learning resources:\n\n$geminiResponse'
              }
            ]
          }),
        );

        if (openRouterResponse.statusCode == 200) {
          final openRouterData = jsonDecode(openRouterResponse.body);
          if (openRouterData['choices'] != null &&
              openRouterData['choices'].isNotEmpty &&
              openRouterData['choices'][0]['message'] != null &&
              openRouterData['choices'][0]['message']['content'] != null) {

            final recommendations = openRouterData['choices'][0]['message']['content'];
            finalResponse = '$geminiResponse\n\nRecommended Resources:\n$recommendations';
          }
        } else {
          debugPrint('OpenRouter API Error: ${openRouterResponse.body}');
        }
      } catch (e) {
        debugPrint('Error getting recommendations: $e');
        // Continue without recommendations if there's an error
      }

      // Translate response back if needed
      if (selectedLanguage != 'en-IN') {
        try {
          final translation = await translator.translate(
            finalResponse,
            from: 'en',
            to: selectedLanguage.split('-')[0],
          );
          finalResponse = translation.text;
        } catch (e) {
          debugPrint('Translation error for response: $e');
          // Continue with English response if translation fails
        }
      }

      // Add AI response to messages
      if (mounted) {
        setState(() {
          userScore += 10;
          messages = [
            ChatMessage(
              user: aiUser,
              createdAt: DateTime.now(),
              text: finalResponse,
            ),
            ...messages
          ];
        });

        try {
          flutterTts.speak(finalResponse);
        } catch (e) {
          debugPrint('TTS error: $e');
        }
      }
    } catch (e) {
      debugPrint("Error in _sendMessage: $e");
      if (mounted) {
        setState(() {
          messages = [
            ChatMessage(
              user: aiUser,
              createdAt: DateTime.now(),
              text:
              "Sorry, I'm having trouble processing your request. Please try again.",
            ),
            ...messages
          ];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _sendMediaMessage() async {
    try {
      ImagePicker picker = ImagePicker();
      XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
      );
      if (file != null) {
        ChatMessage chatMessage = ChatMessage(
          user: currentUser,
          createdAt: DateTime.now(),
          text:
          "Please analyze this image, explain the topic, and suggest educational YouTube videos that can help me learn more about it:",
          medias: [
            ChatMedia(
              url: file.path,
              fileName: file.name,
              type: MediaType.image,
            )
          ],
        );
        _sendMessage(chatMessage);
      }
    } catch (e) {
      debugPrint('Error selecting image: $e');
      _showErrorDialog('Failed to select image: $e');
    }
  }
}