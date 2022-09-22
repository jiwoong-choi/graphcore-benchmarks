FROM graphcore/pytorch:2.6.0-ubuntu-18.04
SHELL ["/bin/bash", "-c"]

RUN apt-get update
RUN apt-get install -y make cmake virtualenv git nano tree htop neofetch
RUN git clone https://github.com/mlcommons/training_results_v2.0 mlcommons

WORKDIR /mlcommons/Graphcore/benchmarks/bert/implementations/popart

RUN make
RUN virtualenv -p python3 --system-site-packages /venv
RUN source /venv/bin/activate && pip install -r requirements.txt && pip install wandb
