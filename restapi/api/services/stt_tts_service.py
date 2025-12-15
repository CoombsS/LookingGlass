import base64
import tempfile
import os
from openai import OpenAI


def decode_base64_to_wav(base64_audio: str) -> str:
    """
    Decodes base64 encoded audio into a temporary WAV file.

    Args:
        base64_audio: Base64 encoded audio string

    Returns:
        str: Path to the temporary WAV file
    """
    audio_data = base64.b64decode(base64_audio)

    # Create a temporary file with .wav extension
    temp_file = tempfile.NamedTemporaryFile(delete=False, suffix='.wav')
    temp_file.write(audio_data)
    temp_file.close()

    return temp_file.name


def transcribe_audio_with_whisper(wav_filename: str, api_key: str = None) -> str:
    """
    Transcribes speech from a WAV file using OpenAI Whisper.

    Args:
        wav_filename: Path to the WAV file
        api_key: OpenAI API key (optional if set in environment)

    Returns:
        str: Transcribed speech text
    """
    client = OpenAI(api_key=api_key) if api_key else OpenAI()

    with open(wav_filename, 'rb') as audio_file:
        transcript = client.audio.transcriptions.create(
            model="whisper-1",
            file=audio_file
        )

    return transcript.text


def text_to_speech_base64(text: str, api_key: str = None, voice: str = "alloy") -> str:
    """
    Converts text to speech and returns base64 encoded audio.

    Args:
        text: The text to convert to speech
        api_key: OpenAI API key (optional if set in environment)
        voice: Voice to use (alloy, echo, fable, onyx, nova, shimmer)

    Returns:
        str: Base64 encoded audio string
    """
    client = OpenAI(api_key=api_key) if api_key else OpenAI()

    response = client.audio.speech.create(
        model="tts-1",
        voice=voice,
        input=text
    )

    # Get the audio content as bytes
    audio_bytes = response.content

    # Encode to base64
    base64_audio = base64.b64encode(audio_bytes).decode('utf-8')

    return base64_audio


# Example usage
if __name__ == "__main__":
    # Example 1: Decode base64 to WAV
    # base64_string = "your_base64_encoded_audio_here"
    # wav_path = decode_base64_to_wav(base64_string)
    # print(f"WAV file created at: {wav_path}")

    # Example 2: Transcribe audio
    # transcription = transcribe_audio_with_whisper(wav_path)
    # print(f"Transcription: {transcription}")

    # Example 3: Text to speech
    # base64_audio = text_to_speech_base64("Hello, this is a test.")
    # print(f"Base64 audio: {base64_audio[:50]}...")

    # Don't forget to clean up temporary files
    # os.remove(wav_path)
    pass