# nginx-echo-headers

A simple tool for debugging HTTP requests. nginx will return all request headers and body to the client.

For the Docker image, see https://github.com/SirCAS/nginx-echo-headers/pkgs/container/nginx-echo-headers

The project is based off the works on https://github.com/brndnmtthws/nginx-echo-headers but allows non-root user for running the container image.


### Running with plain docker

Try running it like so:

```ShellSession
$ docker run -u 101:101 -p 8080:8080 ghcr.io/sircas/nginx-echo-headers
Unable to find image 'ghcr.io/sircas/nginx-echo-headers:latest' locally
latest: Pulling from ghcr.io/sircas/nginx-echo-headers
530afca65e2e: Pull complete 
072ff913b73f: Pull complete 
e39b9f0ae879: Pull complete 
76220cdacc7a: Pull complete 
51787f289c82: Pull complete 
b02224ea6e2c: Pull complete 
Digest: sha256:e3961f532025d56091967049b13a0fa81827d2c781dc9e6e93d9935f37e7723e
Status: Downloaded newer image for ghcr.io/sircas/nginx-echo-headers:latest
2022/10/11 10:43:25 [notice] 1#1: using the "epoll" event method
2022/10/11 10:43:25 [notice] 1#1: openresty/1.21.4.1
2022/10/11 10:43:25 [notice] 1#1: built by gcc 11.2.1 20220219 (Alpine 11.2.1_git20220219) 
2022/10/11 10:43:25 [notice] 1#1: OS: Linux 5.14.0-1033-oem
2022/10/11 10:43:25 [notice] 1#1: getrlimit(RLIMIT_NOFILE): 1048576:1048576
2022/10/11 10:43:25 [notice] 1#1: start worker processes
2022/10/11 10:43:25 [notice] 1#1: start worker process 7
```


### Sending requests to the server

```ShellSession
$ curl -v http://localhost:8080
*   Trying 127.0.0.1:8080...
* Connected to localhost (127.0.0.1) port 8080 (#0)
> GET / HTTP/1.1
> Host: localhost:8080
> User-Agent: curl/7.81.0
> Accept: */*
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< Server: openresty/1.21.4.1
< Date: Tue, 11 Oct 2022 10:44:47 GMT
< Content-Type: text/plain
< Transfer-Encoding: chunked
< Connection: keep-alive
< 
GET / HTTP/1.1
Host: localhost:8080
User-Agent: curl/7.81.0
Accept: */*



de034d36d00b
* Connection #0 to host localhost left intact
```


### Running with k8s

The following is an example of running the image with k8s and an istio gateway.


```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: http-header-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/instance: http-header-test
      app.kubernetes.io/name: http-header-test
  template:
    metadata:
      labels:
        app.kubernetes.io/instance: http-header-test
        app.kubernetes.io/name: http-header-test
        sidecar.istio.io/inject: "true"
    spec:
      containers:
        - image: ghcr.io/sircas/nginx-echo-headers:latest
          name: server
          ports:
            - containerPort: 8080
              name: http
              protocol: TCP
          resources:
            requests:
              cpu: 50m
              memory: 100Mi
            limits:
              memory: 100Mi
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop:
                - ALL
            runAsNonRoot: true
            runAsUser: 101
            runAsGroup: 101
      restartPolicy: Always
      securityContext: {}
---
apiVersion: v1
kind: Service
metadata:
  name: http-header-test
spec:
  type: ClusterIP
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: 8080
  selector:
    app.kubernetes.io/instance: http-header-test
    app.kubernetes.io/name: http-header-test
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: http-header-test
spec:
  hosts:
    - http-header-test.your.cloud
  gateways:
    - istio-ingress/default
    - mesh
  http:
    - name: "http-header-test"
      route:
        - destination:
            host: http-header-test
```

