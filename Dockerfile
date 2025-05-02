FROM python:3.11.0-slim

WORKDIR /data/Resume-Matcher

# Install only necessary dependencies and clean up
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential python-dev git \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Upgrade pip and install requirements
RUN pip install --no-cache-dir -U pip setuptools wheel
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy only necessary files
COPY streamlit_app.py run_first.py ./

# Create non-root user
RUN useradd -m appuser
USER appuser

# Expose port via environment variable
ENV STREAMLIT_SERVER_PORT=8501
EXPOSE $STREAMLIT_SERVER_PORT

# Healthcheck for Streamlit
HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl --fail http://localhost:$STREAMLIT_SERVER_PORT/_stcore/health || exit 1

# Run setup script and Streamlit at runtime
ENTRYPOINT ["sh", "-c", "python run_first.py && streamlit run streamlit_app.py"]
