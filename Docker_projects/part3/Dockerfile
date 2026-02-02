FROM python:3.12-alpine AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip wheel --no-cache-dir --wheel-dir=/usr/local/wheels -r requirements.txt


FROM python:3.12-alpine
WORKDIR /app
COPY --from=builder /usr/local/wheels /wheels  
COPY requirements.txt . 
RUN pip install --no-cache-dir -r requirements.txt --no-index --find-links=/wheels 
COPY hello.py .
EXPOSE 5000
CMD ["python", "hello.py"]

