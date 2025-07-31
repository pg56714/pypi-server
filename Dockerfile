FROM python:3.11

# Install pypiserver
RUN pip install "pypiserver[passlib]"

# Set working directory
WORKDIR /pypi

# Copy password file into the container
COPY pypi_password.txt /pypi_password.txt

# Expose port
EXPOSE 8010

# Set startup command
CMD ["pypi-server", "run", "-p", "8010", "--passwords", "/pypi_password.txt", "/pypi_packages"]
