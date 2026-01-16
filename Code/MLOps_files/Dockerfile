# Base image
FROM public.ecr.aws/docker/library/python:3.7

# Expose port
EXPOSE 5000/tcp

# Set working directory
WORKDIR /app

# Copy everything from host into container
COPY ./ ./ 

# Upgrade pip and install dependencies
RUN /usr/local/bin/python -m pip install --upgrade pip
RUN pip install -r requirements.txt

# Run the Flask app
CMD ["python", "./app.py"]