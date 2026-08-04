
# Homework — RBAC (beginner level)

## Tasks

### 1. Create a namespace
Create a namespace called `anyops-rbac`. Every resource below must live inside it.

### 2. Create a ServiceAccount
Create a ServiceAccount called `student`.

### 3. Create a Role
Create a Role called `pod-reader`. It may **only** `get`, `list` and `watch` pods.
Nothing else: no `create`, no `delete`, no secrets.


### 4. Create a RoleBinding
Create a RoleBinding called `app-reader` that binds the `student` ServiceAccount to the `pod-reader` Role.

![App Screenshot](images/output1.png)

### 5. Check the permissions
Use `kubectl auth can-i` to answer each of these and write down the result:

| # | What we're checking | Your answer |
|---|---------------------|-------------|
| 1 | Can `student` **get** pods in `anyops-rbac`? | yes |
| 2 | Can `student` **list** pods in `anyops-rbac`? | yes |
| 3 | Can `student` **delete** pods in `anyops-rbac`? | no |
| 4 | Can `student` read **secrets** in `anyops-rbac`? | no |
| 5 | Can `student` get pods in the `default` namespace? | no |

![App Screenshot](images/output2.png)

> The `--as=system:serviceaccount:<namespace>:<sa-name>` flag lets you check permissions as if you were that account.

### 6. Try it for real (optional, but recommended)
Run a simple `nginx` pod in the namespace, then list pods as `student`. Did it work? Now try to delete that pod as `student` — what happened, and what exactly does the error message say?

![App Screenshot](images/output3.png)

## Tasks

### 1. Create a namespace
Create a namespace called `anyops-rbac`. Every resource below must live inside it.

### 2. Create a ServiceAccount
Create a ServiceAccount called `student`.

### 3. Create a Role
Create a Role called `pod-reader`. It may **only** `get`, `list` and `watch` pods.
Nothing else: no `create`, no `delete`, no secrets.


### 4. Create a RoleBinding
Create a RoleBinding called `app-reader` that binds the `student` ServiceAccount to the `pod-reader` Role.

![App Screenshot](images/output1.png)

### 5. Check the permissions
Use `kubectl auth can-i` to answer each of these and write down the result:

| # | What we're checking | Your answer |
|---|---------------------|-------------|
| 1 | Can `student` **get** pods in `anyops-rbac`? | yes |
| 2 | Can `student` **list** pods in `anyops-rbac`? | yes |
| 3 | Can `student` **delete** pods in `anyops-rbac`? | no |
| 4 | Can `student` read **secrets** in `anyops-rbac`? | no |
| 5 | Can `student` get pods in the `default` namespace? | no |

![App Screenshot](images/output2.png)

> The `--as=system:serviceaccount:<namespace>:<sa-name>` flag lets you check permissions as if you were that account.

### 6. Try it for real (optional, but recommended)
Run a simple `nginx` pod in the namespace, then list pods as `student`. Did it work? Now try to delete that pod as `student` — what happened, and what exactly does the error message say?

![App Screenshot](images/output3.png)
## Answers

## 1. Why isn't creating just a Role enough?

A `Role` only **defines** a set of permissions (which verbs are allowed on which resources) — it doesn't say **who** gets those permissions. It's like writing a job description but never assigning anyone to the job.

You need a `RoleBinding` to actually connect the Role to a subject (a `User`, `Group`, or `ServiceAccount`). Without the binding, the Role exists in the cluster but grants access to nobody.

This is exactly what happened in the walkthrough: the `pod-reader` Role existed after `kubectl apply`, but `student` still had no permissions until the `app-reader` RoleBinding was created to tie the Role to the `student` ServiceAccount.

## 2. What's the difference between a Role and a ClusterRole?

| | Role | ClusterRole |
|---|---|---|
| Scope | Namespace-scoped | Cluster-scoped |
| Applies to | Resources in one namespace only | Can apply cluster-wide, or to non-namespaced resources |
| Example use | `pod-reader` in `anyops-rbac` only | Access to `nodes`, `persistentvolumes`, `namespaces`, or a reusable role across many namespaces |

- A **Role**'s permissions only apply within the one namespace it's created in. Even when bound, the subject can't use those permissions in any other namespace.
- A **ClusterRole** is reusable and can grant permissions across all namespaces, or be used for cluster-level resources that don't belong to any namespace at all.

Whether a ClusterRole's permissions apply cluster-wide or just to one namespace depends on **how it's bound**:
- `ClusterRoleBinding` → applies cluster-wide.
- `RoleBinding` (referencing a ClusterRole) → applies only within that one namespace.

This last pattern is common: define a ClusterRole once, then bind it in multiple namespaces via separate RoleBindings — avoiding duplicate Role definitions.

## 3. If `watch` were missing from `pod-reader`, would `kubectl get pods -w` still work?

**No.**

The `-w` (`--watch`) flag opens a **watch** connection to the API server to stream changes in real time. This uses the `watch` verb specifically — distinct from `get` or `list`.

Without `watch` in the Role, the command would fail with something like:

```
Error from server (Forbidden): pods is forbidden: User "student" cannot watch resource "pods" in API group "" in the namespace "anyops-rbac"
```

`get` and `list` would still work fine for one-time reads — only the streaming/watch behavior would break.

## 4. If you wanted to give the same Role to 5 different ServiceAccounts, how many Roles and how many RoleBindings would you write?

- **1 Role** — permissions are reused, not duplicated.
- **5 RoleBindings** — one per ServiceAccount, in the "one binding per grant" mental model.

**Alternative:** a single RoleBinding can list multiple subjects, so it's also valid to use **1 Role + 1 RoleBinding**:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pod-reader-binding
  namespace: anyops-rbac
subjects:
- kind: ServiceAccount
  name: student1
  namespace: anyops-rbac
- kind: ServiceAccount
  name: student2
  namespace: anyops-rbac
- kind: ServiceAccount
  name: student3
  namespace: anyops-rbac
- kind: ServiceAccount
  name: student4
  namespace: anyops-rbac
- kind: ServiceAccount
  name: student5
  namespace: anyops-rbac
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

Both approaches are valid — "5 RoleBindings" is the more common/expected answer, but the multi-subject shortcut is worth knowing.
