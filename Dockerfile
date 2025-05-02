FROM python:3.11.0-slim

WORKDIR /data/Resume-Matcher

# Install dependencies and clean up
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential python-dev libpq-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip install --no-cache-dir pip==23.3.1 setuptools==68.2.2 wheel==0.41.2
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY streamlit_app.py run_first.py ./
COPY scripts/ scripts/
COPY Data/ Data/

# Create non-root user
RUN useradd -m appuser

# Set ownership and permissions for appuser
RUN chown -R appuser:appuser /data/Resume-Matcher
RUN chmod -R u+rwX /data/Resume-Matcher
# Ensure scripts are executable
RUN chmod u+x /data/Resume-Matcher/streamlit_app.py /data/Resume-Matcher/run_first.py
# Ensure write access to Data/Processed and logs (created at runtime)
RUN mkdir -p /data/Resume-Matcher/Data/Processed /data/Resume-Matcher/Data/Processed/Resumes /data/Resume-Matcher/Data/Processed/JobDescription /data/Resume-Matcher/logs
RUN chown -R appuser:appuser /data/Resume-Matcher/Data/Processed /data/Resume-Matcher/logs
RUN chmod -R u+rwx /data/Resume-Matcher/Data/Processed /data/Resume-Matcher/logs

# Switch to non-root user
USER appuser

# Set Streamlit port
ENV STREAMLIT_SERVER_PORT=8501
EXPOSE $STREAMLIT_SERVER_PORT

# Healthcheck for Streamlit
HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl --fail http://localhost:$STREAMLIT_SERVER_PORT/_stcore/health || exit 1

# Run preprocessing and Streamlit at runtime
ENTRYPOINT ["sh", "-c", "python run_first.py && streamlit run streamlit_app.py"]
