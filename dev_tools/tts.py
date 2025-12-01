from tts_exercises import exercises

from gtts import gTTS

language = "sw"

for e in exercises:
    id = e["id"]
    for i, s in enumerate(e["sentences"]):
        sound = gTTS(text=s, lang=language, slow=False)
        sound.save(f"audio/{id}_{i}.mp3")
print("done")

