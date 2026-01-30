FROM python:3.12-alpine AS builder
WORKDIR /app
RUN pip install Flask
COPY hello.py . 

FROM python:3.12-alpine
WORKDIR /app
COPY --from=builder /usr/local /usr/local
COPY --from=builder /app/hello.py .
CMD ["python", "hello.py"]
EXPOSE 5000

