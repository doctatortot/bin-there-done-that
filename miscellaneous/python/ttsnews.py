import feedparser
import requests
import os
from elevenlabs import ElevenLabs

def fetch_news(rss_url):
    """Fetch the latest news article from a satirical RSS feed."""
    feed = feedparser.parse(rss_url)
    if feed.entries:
        article_title = feed.entries[0].title
        article_summary = feed.entries[0].summary
        return article_title, article_summary
    return None, None

def generate_news_script(title, summary):
    """Generate a humorous news script from the full article."""
    if title and summary:
        script = f"Here is your latest Genesis Radio news update. "
        script += f"Today's story: {title}. {summary} "
        script += "For more news and entertainment keep it locked right here on Genesis Radio, Beginning with Great Music!"
        return script
    return "No new satirical news available at the moment."

def text_to_speech(text, output_file="latest_news.mp3"):
    """Convert text to speech using ElevenLabs and save as an MP3 file."""
    elevenlabs = ElevenLabs(api_key="sk_d2c55a2f1f71cd91fb498a986300e0aaf53879e54f53f5c0")
    audio = elevenlabs.generate(
        text=text,
        voice="David Hertel",  # Change to preferred ElevenLabs voice
        model="eleven_multilingual_v2"
    )
    
    audio_bytes = b"".join(audio)  # Convert generator to bytes
    
    with open(output_file, "wb") as f:
        f.write(audio_bytes)
    
    print(f"Satirical news update saved as {output_file}")

def main():
    rss_url = "https://www.theonion.com/rss"  # Satirical news source
    title, summary = fetch_news(rss_url)
    news_script = generate_news_script(title, summary)
    text_to_speech(news_script, "X:/rssnews/latest_news.mp3")  # Adjust path as needed

if __name__ == "__main__":
    main()

