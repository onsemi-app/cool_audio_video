# Execute this block on your machine right now to save your official setup file:
cat << 'EOF' > ~/repos/cool_demo/Google_Gemma/Gemma4/vla_docker/DEPLOYMENT_MANUAL.txt
================================================================================
🚀 COMPREHENSIVE PRODUCTION DEPLOYMENT & OPERATION MANUAL (JETPACK 6.x)
================================================================================

[1] SYSTEM INFRASTRUCTURE DIRECTORY TREE
--------------------------------------------------------------------------------
Ensure your target host filesystem adheres to this exact canonical structure:
~/
├── models/
│   ├── gemma-4-E2B-it-Q4_K_M.gguf      # Main LLM Backbone Weights
│   └── mmproj-gemma4-e2b-f16.gguf     # Companion Vision Projector
└── repos/
    └── cool_demo/
        └── Google_Gemma/
            └── Gemma4/                # Main Application Repository Root
                ├── Gemma4_vla.py       # Interactivity Application Script
                └── vla_docker/        # Isolated Containerization Scope
                    ├── Dockerfile.server
                    ├── Dockerfile.agent
                    └── docker-compose.yml

[2] DEVELOPMENT ENVIRONMENT CONFIGURATION FILES
--------------------------------------------------------------------------------

💾 FILE A: ~/repos/cool_demo/Google_Gemma/Gemma4/vla_docker/Dockerfile.server
--------------------------------------------------------------------------------
# STAGE 1: Sandbox Compiler Layer
FROM nvcr.io/nvidia/pytorch:23.10-py3 AS builder
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y git cmake build-essential && rm -rf /var/lib/apt/lists/*
WORKDIR /build
RUN git clone https://github.com && \
    cd llama.cpp && \
    cmake -B build \
      -DCMAKE_CUDA_ARCHITECTURES="87" \
      -DGGML_CUDA=ON \
      -DGGML_NCCL=OFF \
      -DCMAKE_DISABLE_FIND_PACKAGE_NCCL=ON \
      -DCMAKE_EXE_LINKER_FLAGS="-L/usr/local/cuda/lib64/stubs -lcuda" \
      -DCMAKE_SHARED_LINKER_FLAGS="-L/usr/local/cuda/lib64/stubs -lcuda" && \
    cmake --build build --config Release --target llama-server -j$(nproc)

# STAGE 2: Lightweight Production Runtime Shell
FROM nvcr.io/nvidia/l4t-base:r36.2.0
ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /app
COPY --from=builder /build/llama.cpp/build/bin/llama-server /usr/local/bin/llama-server
COPY --from=builder /build/llama.cpp/build/bin/*.so* /usr/local/lib/
RUN ldconfig
EXPOSE 8080
ENTRYPOINT ["llama-server"]
--------------------------------------------------------------------------------

💾 FILE B: ~/repos/cool_demo/Google_Gemma/Gemma4/vla_docker/Dockerfile.agent
--------------------------------------------------------------------------------
FROM nvcr.io/nvidia/pytorch:23.10-py3
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    libasound2-dev portaudio19-dev libgl1-mesa-glx pulseaudio-utils alsa-utils wget psmisc \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
RUN pip3 install --no-cache-dir --upgrade pip setuptools wheel
RUN pip3 install --no-cache-dir \
    onnxruntime==1.19.2 numpy==1.26.4 sounddevice soundfile requests opencv-python onnx-asr \
    espeakng-loader phonemizer-fork huggingface_hub attrs scipy tqdm certifi filelock fsspec pyyaml h5py typing-extensions
RUN pip3 install --no-cache-dir --no-dependencies kokoro-onnx==0.5.0 opencv-python-headless
COPY . /app/
ENV PYTHONPATH="/app:${PYTHONPATH}"
CMD ["python3", "Gemma4_vla.py"]
--------------------------------------------------------------------------------

💾 FILE C: ~/repos/cool_demo/Google_Gemma/Gemma4/vla_docker/docker-compose.yml
--------------------------------------------------------------------------------
services:
  gemma-backend:
    image: jetson-gemma4-server:latest
    build:
      context: .
      dockerfile: Dockerfile.server
    runtime: nvidia
    network_mode: "host"
    ipc: host
    ulimits:
      memlock: -1
      stack: 67108864
    volumes:
      - ~/models:/models
      - /usr/local/cuda:/usr/local/cuda
    environment:
      - LD_LIBRARY_PATH=/usr/local/cuda/targets/aarch64-linux/lib:/usr/local/cuda/lib64:/usr/local/lib
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=all
    command: >
      --model /models/gemma-4-E2B-it-Q4_K_M.gguf
      --mmproj /models/mmproj-gemma4-e2b-f16.gguf
      --port 8080
      --ctx-size 2048
      --parallel 1
      --flash-attn on
      --n-gpu-layers 99
    restart: unless-stopped

  vla-agent:
    image: jetson-gemma4-agent:latest
    build:
      context: .
      dockerfile: Dockerfile.agent
    network_mode: "host"
    ipc: host
    depends_on:
      - gemma-backend
    devices:
      - "/dev/video0:/dev/video0"
      - "/dev/snd:/dev/snd"
    volumes:
      - /run/user/1000/pulse:/run/user/1000/pulse
      - ~/.config/pulse/cookie:/root/.config/pulse/cookie
      - ~/.cache/huggingface:/root/.cache/huggingface
      - ~/repos/cool_demo/Google_Gemma/Gemma4:/app
    environment:
      - PULSE_SERVER=unix:/run/user/1000/pulse/native
      - MIC_DEVICE=plughw:0,0
      - SPK_DEVICE=bluez_sink.A0_E9_DB_00_B1_10.a2dp_sink
      - PYTHONPATH=/app
    stdin_open: true
    tty: true
--------------------------------------------------------------------------------

[3] ONE-TIME COMPILATION & ARCHIVE PORTABILITY EXPORT
--------------------------------------------------------------------------------
Execute these host shell blocks to compile images and package them into tarballs:

cd ~/repos/cool_demo/Google_Gemma/Gemma4/vla_docker

# 1. Compile both architecture layers simultaneously
DOCKER_BUILDKIT=0 docker compose build

# 2. Compress and serialize built image caches into deployment packages
docker save jetson-gemma4-server:latest | gzip > ~/archive_server.tar.gz
docker save jetson-gemma4-agent:latest | gzip > ~/archive_agent.tar.gz
tar -czf ~/archive_repo_vla.tar.gz -C ~/repos/cool_demo/Google_Gemma Gemma4

[4] TARGET SITE REPLICABILITY & DEPLOYMENT MANUAL
================================================================================
When initializing a remotely located new site running JetPack 6.x hardware:

STEP 1: PREPARE FILE DIRECTORIES
--------------------------------------------------------------------------------
mkdir -p ~/models
mkdir -p ~/repos/cool_demo/Google_Gemma

# Transport your weights files via USB drive or network sync into place:
# -> Put 'gemma-4-E2B-it-Q4_K_M.gguf' and 'mmproj-gemma4-e2b-f16.gguf' inside ~/models/

STEP 2: EXTRACT PORTABLE FILES & LOAD CONTAINER PACKAGES
--------------------------------------------------------------------------------
# Unpack the repository workspace scripts
tar -xzf archive_repo_vla.tar.gz -C ~/repos/cool_demo/Google_Gemma

# Load image layers directly into the remote machine's active Docker core engine
docker load < archive_server.tar.gz
docker load < archive_agent.tar.gz

STEP 3: EXECUTE OPERATIONAL ORCHESTRATION PIPELINE
--------------------------------------------------------------------------------
# 1. Maximize physical clock limits (Mandatory on reboot)
sudo nvpmodel -m 0 && sudo jetson_clocks

# 2. Clear any lingering port allocations
sudo pkill -f llama-server

# 3. Enter workspace directory and pull up orchestration clusters
cd ~/repos/cool_demo/Google_Gemma/Gemma4/vla_docker
docker compose up -d

# 4. Attach terminal input pipelines directly to capture keyboard hooks
docker attach vla_docker-vla-agent-1
================================================================================
EOF
