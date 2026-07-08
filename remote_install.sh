#!/bin/bash
# Complete bare-metal automated deployment script for field hardware

echo "🚀 [1/4] Optimizing Jetson MAX-Performance Clock Arrays..."
sudo nvpmodel -m 0 && sudo jetson_clocks

echo "📂 [2/4] Initializing Target Model Filesystem Infrastructure..."
mkdir -p ~/models
mkdir -p ~/.cache/huggingface

echo "🔌 [3/4] Clearing Lingering Host Port Allocations..."
sudo pkill -f llama-server

echo "🦅 [4/4] Deploying Docker Compose Multi-Container Orchestration Cluster..."
docker compose up -d

echo "🟢 System Initialization Successful! Attaching Terminal Stream Input..."
sleep 2
docker attach vla_docker-vla-agent-1
