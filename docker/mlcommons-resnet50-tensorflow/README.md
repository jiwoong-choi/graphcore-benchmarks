# MLCommon Resnet50 Tensorflow1

## 1. Build docker image


```bash
docker build -t graphcore-bmt:mlcommons-resnet50-tensorflow .
```

## 2. Create a docker container

```bash
gc-docker -- -d --rm -it --name mlcommons_resnet50_tensorflow -p <host-port>:<container-port> -v <imagenet-tfrecord-path>:/dataset graphcore-bmt:mlcommons-resnet50-tensorflow
```

## 3. Execute docker container shell

```bash
docker exec -it mlcommons_resnet50_tensorflow bash
```

## 4. Run training script on the container shell

This step might take more than an hour. The output file `nohup.out` will give you instruction on how to monitor the training.
You can exit the container shell while this process is running, and come back for the final results.

```bash
nohup bash run.sh /dataset &
```

## 5. Check the results on the container shell

```bash
find logs -name log.txt -exec tail -n 15 {} +
```
