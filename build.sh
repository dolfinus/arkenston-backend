#!/bin/bash
docker build -t dolfinus/arkenston-backend:base  -t dolfinus/arkenston-backend:base-latest  --compress -f Dockerfile.base  .
docker build -t dolfinus/arkenston-backend:build -t dolfinus/arkenston-backend:build-latest --compress -f Dockerfile.build .
docker-compose -f docker-compose.dev.yml up -d --build
docker-compose -f docker-compose.test.yml up -d --build
docker-compose -f docker-compose.yml up -d --build
