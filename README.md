# XNAT Helm #

This is a basic Helm chart to get XNAT up and running. It includes the following services:

* xnat-web
* xnat-db

This Helm chart is based on original work by Anurag Guda from NVIDIA.

## Deploying ##

To deploy, you need the following tools:

* A Kubernetes cluster
* [Helm](https://helm.sh/docs/intro/install)

### Local Kubernetes cluster ###

This presumes you're working in the same folder as the file [Chart.yaml](Chart.yaml).

First, install the Helm chart:

```bash
$ helm install xnat .
```

Verify everything loaded properly:

```bash
$ kubectl get pods,services,deployments
NAME                            READY   STATUS    RESTARTS   AGE
pod/xnat-db-5bd49488bf-tnvwv    1/1     Running   0          23m
pod/xnat-web-84854f6787-vrtlp   1/1     Running   0          23m

NAME                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                                      AGE
service/kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP                                      14d
service/xnat-db      ClusterIP   10.103.98.147   <none>        5432/TCP                                     23m
service/xnat-web     NodePort    10.99.240.13    <none>        8081:30001/TCP,8000:32094/TCP,22:31058/TCP   23m

NAME                             READY   UP-TO-DATE   AVAILABLE   AGE
deployment.extensions/xnat-db    1/1     1            1           23m
deployment.extensions/xnat-web   1/1     1            1           23m
```

Get the port on which the **xnat-web** service is exposed:

```bash
$ kubectl get --namespace default -o jsonpath="{.spec.ports[0].nodePort}" svc xnat-web)
30001%
```

Ignore the '%' character, it's essentially an EOF without a new line.

You can monitor the XNAT start-up log using the name of the **xnat-web** pod:

```bash
$ kubectl logs pod/xnat-web-84854f6787-vrtlp
```

Once XNAT has completed start-up, you can access it via [http://localhost:30001](http://localhost:30001).

You can stop your deployment by uninstalling the Helm chart:

```bash
$ helm uninstall xnat
```

### External Kubernetes cluster ###

_TBD_
