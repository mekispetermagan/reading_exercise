from tts_exercises_luganda import exercises

import torchaudio
from speechbrain.pretrained import Tacotron2, HIFIGAN
from pydub import AudioSegment

tacotron2 = Tacotron2.from_hparams(source="Sunbird/tts-tacotron2-lug", savedir="tmpdir_tts")
hifi_gan = HIFIGAN.from_hparams(source="speechbrain/tts-hifigan-ljspeech", savedir="tmpdir_vocoder")

for e in exercises:
    ex_id = e["id"]
    for i, s in enumerate(e["sentences"]):
        mel, _, _ = tacotron2.encode_text(s)
        wav = hifi_gan.decode_batch(mel)
        wav_path = f"audio/{ex_id}_{i}.wav"
        mp3_path = f"audio/{ex_id}_{i}.mp3"

        torchaudio.save(wav_path, wav.squeeze(1), 22050)
        AudioSegment.from_wav(wav_path).export(mp3_path, format="mp3")

print("done")
