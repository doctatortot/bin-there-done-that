# Use the official Python image
FROM python:3.12-slim

# Set the working directory inside the container
WORKDIR /app

# Copy the application code into the container
COPY . /app/

# Install dependencies from requirements.txt inside the container
RUN pip install --no-cache-dir -r requirements.txt

# Expose the port your app will run on (adjust as needed)
EXPOSE 5000

# Command to run the application (adjust script name)
CMD ["python", "recordit2.py"]
