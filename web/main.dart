/// A metronome. Supports tap tempo, and playing a click track.
library main;

import 'dart:async';
import 'dart:html';
import 'dart:typed_data';
import 'dart:web_audio';

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
final Element tap = querySelector('#tap');

/// The input element for the number of beats in the bar.
final NumberInputElement beats = querySelector('#beats')as NumberInputElement;

/// The play button.
final Element play = querySelector('#play');

/// The current beat in the bar.
int currentBeat = 0;

/// The metronome timer.
Timer timer;

/// The main function.
void main() {
  audio = AudioContext();
  getBuffer('click.wav', (AudioBuffer buffer) {
    document.title = 'Metronome';
    output.hidden = false;
    tempoElement.onChange.listen((Event e) {
      tempo = int.tryParse(tempoElement.value);
      if (tempo >= int.tryParse(tempoElement.min) && timer != null) {
        stopTimer();
        startTimer(buffer);
      }
    });
    play.onClick.listen((MouseEvent e) {
      tempo = int.tryParse(tempoElement.value);
      if (timer == null) {
        startTimer(buffer);
        play.innerText = 'Stop';
      } else {
        stopTimer();
        play.innerText = 'Play';
      }
    });
  });
}

/// Start the metronome clicking.
void startTimer(AudioBuffer buffer) {
  click(buffer);
  timer = Timer.periodic(Duration(milliseconds: (1000 / (tempo / 60)).round()), (Timer t) => click(buffer));
}

/// Stop the metronome from clicking.
void stopTimer() {
  timer.cancel();
  timer = null;
}

void click(AudioBuffer buffer) {
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
