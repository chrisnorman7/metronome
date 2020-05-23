/// A metronome. Supports tap tempo, and playing a click track.
library main;

import 'dart:async';
import 'dart:html';
import 'dart:typed_data';
import 'dart:web_audio';

/// The audio buffer to use.
AudioBuffer buffer;
/// The audio system.
AudioContext audio;

/// Get an [AudioBuffer] from url.
void getBuffer(String url, void Function(AudioBuffer) done) {
  final HttpRequest xhr = HttpRequest();
  xhr.responseType = 'arraybuffer';
  xhr.open('GET', url);
  xhr .onLoad.listen(
    (ProgressEvent e) async {
      try {
        final AudioBuffer buffer = await audio.decodeAudioData(xhr.response as ByteBuffer);
        done(buffer);
      }
      catch(e) {
        throw 'Failed to get "$url": $e';
      }
    }
  );
  xhr.send();
}

/// The output div.
final Element output = querySelector('#output');

/// The BPM control.
final NumberInputElement tempoElement = querySelector('#tempo')as NumberInputElement;

/// The actual tempo.
int tempo;

/// The tap tempo button.
final ButtonElement tapButton = querySelector('#tap') as ButtonElement;

/// The input element for the number of beats in the bar.
final NumberInputElement beats = querySelector('#beats')as NumberInputElement;

/// The play button.
final ButtonElement playButton = querySelector('#play') as ButtonElement;

/// The current beat in the bar.
int currentBeat = 0;

/// The metronome timer.
Timer timer;

/// The main function.
void main() {
  document.title = 'Metronome';
  audio = AudioContext();
  output.hidden = false;
  playButton.focus();
  tempoElement.onChange.listen((Event e) {
    tempo = int.tryParse(tempoElement.value);
    if (tempo >= int.tryParse(tempoElement.min) && timer != null) {
      stopTimer();
      if (buffer != null) {
        startTimer();
      }
    }
  });
  playButton.onClick.listen((MouseEvent e) {
    if (buffer == null) {
      playButton.disabled = false;
      getBuffer('click.wav', (AudioBuffer b) {
        buffer = b;
        playButton.disabled = false;
        startStopMetronome();
      });
    } else {
        startStopMetronome();
    }
  });
}

/// Start or stop the metronome.
void startStopMetronome() {
  tempo = int.tryParse(tempoElement.value);
  if (timer == null) {
    startTimer();
    playButton.innerText = 'Stop';
  } else {
    stopTimer();
    playButton.innerText = 'Play';
  }
}

/// Start the metronome clicking.
void startTimer() {
  click();
  timer = Timer.periodic(Duration(milliseconds: (1000 / (tempo / 60)).round()), (Timer t) => click());
}

/// Stop the metronome from clicking.
void stopTimer() {
  timer.cancel();
  timer = null;
}

/// Make the click sound.
void click() {
  final int numberOfBeats = int.tryParse(beats.value);
  currentBeat++;
  if (currentBeat > numberOfBeats) {
    currentBeat = 1;
  }
  final AudioBufferSourceNode s = audio.createBufferSource();
  s.buffer = buffer;
  if (currentBeat == 1) {
    /// Make the click higher.
    s.playbackRate.value *= 1.5;
  }
  s.connectNode(audio.destination);
  s.start();
}
