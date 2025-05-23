import speech_recognition as sr
import audioop
import numpy as np

def speech_to_text():
    r = sr.Recognizer()
    with sr.Microphone() as source:
        r.adjust_for_ambient_noise(source)
        print("talk bro")
        while True:
            try:
                audio = r.listen(source)
                text = r.recognize_google(audio)
                
                rms_value = audioop.rms(audio.frame_data, audio.sample_width)
                
                max_amplitude = (2**(8 * audio.sample_width - 1)) - 1
                normalized_rms = rms_value / max_amplitude if max_amplitude > 0 else 0.0
                
                words = text.split()
                for word in words:
                    formatted_word = f"[{word}:{normalized_rms:.3f}]"
                    print(formatted_word)
                    with open("mic_system/transcription.txt", "a") as f:
                        f.write(formatted_word + "\n")
                        f.flush()
                
                if "stop" in text.lower():
                    break
            except sr.UnknownValueError:
                print("cant understand yo ahh")
            except Exception as e:
                print(f"An error occurred: {e}")

if __name__ == "__main__":
    speech_to_text()