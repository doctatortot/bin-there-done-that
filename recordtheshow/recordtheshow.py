import os
import subprocess
import argparse
import shutil
from datetime import datetime

# Function to record the radio show using ffmpeg
def record_show(folder_name, duration, filename_prefix):
    # Set the working directory for the recording
    working_directory = "/home/doc/Genesis"
    
    # Ensure the folder exists in archives with the prefix as the folder name
    archives_directory = "/mnt/archives"
    target_folder = os.path.join(archives_directory, filename_prefix)
    if not os.path.exists(target_folder):
        os.makedirs(target_folder)

    # Construct filename based on the prefix and current time
    current_time = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"{filename_prefix}_{current_time}.mp3"
    output_path = os.path.join(working_directory, filename)

    # URL of the radio stream (this should be replaced with the actual stream URL)
    radio_stream_url = "http://stream.genesis-radio.net:7454/stream"  # Replace with your actual stream URL

    # ffmpeg command to record the stream
    ffmpeg_command = [
        "ffmpeg", 
        "-i", radio_stream_url,  # Input stream URL
        "-t", str(duration),      # Duration in seconds
        "-acodec", "libmp3lame",  # Audio codec (MP3)
        "-vn",                    # No video
        output_path               # Output file path
    ]

    try:
        print(f"Recording for {duration} seconds...")
        subprocess.run(ffmpeg_command, check=True)
        print(f"Recording completed, saved to {output_path}")

        # Move the recorded file to the archives folder
        target_path = os.path.join(target_folder, filename)
        shutil.move(output_path, target_path)
        print(f"File moved to {target_path}")
    except subprocess.CalledProcessError as e:
        print(f"Error while recording: {e}")
    except Exception as e:
        print(f"Error moving file: {e}")

# Main function to parse arguments and start recording
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Record a radio show")
    parser.add_argument("filename_prefix", help="The prefix for the folder and filename")
    parser.add_argument("duration", type=int, help="Duration to record in seconds")
    
    args = parser.parse_args()
    
    record_show(args.filename_prefix, args.duration, args.filename_prefix)
