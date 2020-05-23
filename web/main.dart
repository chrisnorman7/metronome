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

/// Get the minimum tempo.
int getMinTempo() => int.tryParse(tempoElement.min);

/// Get the maximum tempo.
int getMaxTempo() => int.tryParse(tempoElement.max);

/// Get the current tempo.
int getTempo() => int.tryParse(tempoElement.value);

/// Returns true if [bpm] is between [tempo.min] and [tempo.last] inclusive.
bool validTempo(int bpm) => bpm >= getMinTempo() && bpm <= getMaxTempo();

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

int lastTap;

/// The main function.
void main() {
  document.title = 'Metronome';
  audio = AudioContext();
  output.hidden = false;
  playButton.focus();
  tempoElement.onChange.listen((Event e) {
    tempo = getTempo();
    if (validTempo(tempo) && timer != null) {
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
  tapButton.onClick.listen((MouseEvent e) {
    if (lastTap != null) {
      final int difference = DateTime.now().millisecondsSinceEpoch - lastTap;
      // Don't do anything if they try and drop the tempo below 30 BPM.
      //
      // Note: This may happen accidentally, if they haven't tapped for a while.
      final int bpm = ((60 / difference) * 1000).floor();
      if (validTempo(bpm)) {
        tempo = bpm;
        tempoElement.value = bpm.toString();
        if (timer != null) {
          stopTimer();
          startTimer();
        }
      }
    }
    lastTap = DateTime.now().millisecondsSinceEpoch;
  });
}

/// Start or stop the metronome.
void startStopMetronome() {
  tempo = int.tryParse(tempoElement.value);
  if (timer == null) {
    currentBeat = 0;
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
