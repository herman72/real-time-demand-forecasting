# Use the official Airflow image as the base
FROM apache/airflow:2.9.2

# Copy your requirements file into the image
COPY requirements.txt /

# Install the Python packages
RUN pip install --no-cache-dir -r /requirements.txt