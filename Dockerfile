# Start from a base Python image
FROM python:3.10-slim

# تحديث وتثبيت الأدوات الأساسية المطلوبة لـ yt-dlp مثل (git, ffmpeg)
# git مطلوب لبعض اعتماديات pip، و ffmpeg لمعالجة الفيديو
RUN apt-get update && \
    apt-get install -y git ffmpeg && \
    rm -rf /var/lib/apt/lists/*

# Set the working directory inside the container
WORKDIR /app

# Copy the requirements file and install dependencies
# هذه هي الخطوة التي كانت تفشل. يجب التأكد من وجود الملف.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application files (app.py and the templates directory)
COPY . .

# Expose the port where your application will run
EXPOSE 7860

# Define the command to run your application using Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:7860", "app:app"]
