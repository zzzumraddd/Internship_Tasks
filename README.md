# Kubernetes Storage Lab (PV, PVC, StorageClass)

## Tasks

### Part 1 — hostPath PV + PVC + Pod

- Create a 1Gi hostPath PV
- Connect to it with a PVC
- Create a Pod and mount the disk to `/data`
- Write a test file inside the Pod
- Delete the Pod, create it again, and check that the file is still there

### Part 2 — StorageClass + Deployment

- Find StorageClass in the cluster: `kubectl get storageclass`
- Create a 1Gi PVC using that StorageClass
- Create a Deployment and mount the PVC to `/data`
- Write data to `/data`

---

## Files used

| File | What it is |
| --- | --- |
| `persistent-volume.yaml` | hostPath PV (1Gi) |
| `persistent-volume-claim.yaml` | PVC for the hostPath PV |
| `pod-with-pvc.yaml` | Pod that mounts PVC at `/data` |
| `pvc_test2.yaml` | PVC using StorageClass |
| `deployment_test2.yaml` | Deployment with PVC mounted at `/data` |

---

## Part 1 — hostPath PV, PVC, Pod

### 1. Create PV

```bash
kubectl apply -f persistent-volume.yaml
kubectl get pv
```

### 2. Create PVC

```bash
kubectl apply -f persistent-volume-claim.yaml
kubectl get pvc
```

PVC should become **Bound**.

### 3. Create Pod and mount at `/data`

```bash
kubectl apply -f pod-with-pvc.yaml
kubectl get pod
```

### 4. Write test file inside the Pod

```bash
kubectl exec -it pod-with-pvc -- sh -c 'echo "salom" > /data/hello.txt'
kubectl exec -it pod-with-pvc -- cat /data/hello.txt
```

### 5. Delete Pod, create again, check file

```bash
kubectl delete pod pod-with-pvc
kubectl apply -f pod-with-pvc.yaml
kubectl exec -it pod-with-pvc -- cat /data/hello.txt
```

The file is still there, because data is stored on the volume, not only in the container.

![App Screenshot](images/output1.png)

---

## Part 2 — StorageClass, PVC, Deployment

### 1. Check StorageClass

```bash
kubectl get storageclass
```

### 2. Add StorageClass on kubeadm (if cluster has none)

kubeadm does not give a StorageClass by default. I installed **local-path** provisioner:

```bash
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.30/deploy/local-path-storage.yaml
```

Wait for the pod:

```bash
kubectl -n local-path-storage get pod
kubectl get storageclass
```

Optional — make it default:

```bash
kubectl patch storageclass local-path -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl get storageclass
```

### 3. Create 1Gi PVC with StorageClass

```bash
kubectl apply -f pvc_test2.yaml
kubectl get pvc
```

### 4. Create Deployment and mount PVC to `/data`

```bash
kubectl apply -f deployment_test2.yaml
kubectl get deploy,pod,pvc
```

### 5. Write to `/data` from the Deployment pod

```bash
POD=$(kubectl get pod -l app=task-storage -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD -- sh -c 'echo "salom" > /data/hello.txt'
kubectl exec -it $POD -- cat /data/hello.txt
```

> If your label is different, use the pod name from `kubectl get pod`.

### 6. Restart pod and check data again

```bash
kubectl delete pod -l app=task-storage
kubectl get pod
POD=$(kubectl get pod -l app=task-storage -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD -- cat /data/hello.txt
```

File is still there.

![App Screenshot](images/output2.png)

---

## Cleanup

```bash
kubectl delete -f deployment_test2.yaml
kubectl delete -f pvc_test2.yaml
kubectl delete -f pod-with-pvc.yaml
kubectl delete -f persistent-volume-claim.yaml
kubectl delete -f persistent-volume.yaml
```

---

## What I learned

- **PV** = storage in the cluster
- **PVC** = request to use that storage
- **hostPath** = folder on the node (simple for labs)
- **StorageClass** = automatic PV creation for PVC
- Data can stay after Pod delete if it is on a volume
