# Resource Generation Graph

This graph shows the relationship between the top-level bb-common keys and the Kubernetes resources they generate.

**Color Legend:**

- 🔵 Blue: Top Level Configuration keys
- 🟠 Orange: Sub-configuration keys
- 🟢 Green: Default resources (typically automatically created)
- 🟣 Purple: Custom resources (user-defined)

## Network Policies

### Egress

```mermaid
graph TB
    A[networkPolicies] --> A1[egress]

    A1 --> A1A[NetworkPolicy:<br/>deny-all]
    A1 --> A1B[NetworkPolicy:<br/>allow-in-ns]
    A1 --> A1C[NetworkPolicy:<br/>allow-kube-dns]
    A1 --> A1D[NetworkPolicy:<br/>allow-istiod]
    A1 --> A3[NetworkPolicy:<br/>custom]

    %% Styling
    classDef configKeys fill:#e1f5fe,stroke:#01579b,stroke-width:2px,color:black;
    classDef resources fill:#f3e5f5,stroke:#4a148c,stroke-width:2px,color:black;
    classDef subKeys fill:#fff3e0,stroke:#e65100,stroke-width:2px,color:black;
    classDef defaults fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px,color:black;

    class A configKeys;
    class A1 subKeys;
    class A1A,A1B,A1C,A1D defaults;
    class A3 resources;
```

---

### Ingress

```mermaid
graph TB
    A[networkPolicies] --> A2[ingress]

    A2 --> A2A[NetworkPolicy:<br/>deny-all]
    A2 --> A2B[NetworkPolicy:<br/>allow-in-ns]
    A2 --> A2C[NetworkPolicy:<br/>allow-prometheus]
    A2 --> A6[NetworkPolicy:<br/>custom]
    A2 --> A7[AuthorizationPolicy:<br/>custom]

    %% Styling
    classDef configKeys fill:#e1f5fe,stroke:#01579b,stroke-width:2px,color:black;
    classDef resources fill:#f3e5f5,stroke:#4a148c,stroke-width:2px,color:black;
    classDef subKeys fill:#fff3e0,stroke:#e65100,stroke-width:2px,color:black;
    classDef defaults fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px,color:black;

    class A configKeys;
    class A2 subKeys;
    class A2A,A2B,A2C defaults;
    class A6,A7 resources;
```

---

## Routes

```mermaid
graph TB
    B[routes] --> B1[inbound]

    B1 --> B1A[VirtualService]
    B1 --> B1B[ServiceEntry]
    B1 --> B1C[NetworkPolicy:<br/>allow-from-gateway]
    B1 --> B1D[AuthorizationPolicy:<br/>allow-from-gateway]

    %% Styling
    classDef configKeys fill:#e1f5fe,stroke:#01579b,stroke-width:2px,color:black;
    classDef resources fill:#f3e5f5,stroke:#4a148c,stroke-width:2px,color:black;
    classDef subKeys fill:#fff3e0,stroke:#e65100,stroke-width:2px,color:black;

    class B configKeys;
    class B1 subKeys;
    class B1A,B1B,B1C,B1D resources;
```

---

## Istio

```mermaid
graph TB
    C[istio] --> C1[authorizationPolicies]
    C --> C2[hardened]
    C --> C3[mtls]

    C1 --> C1A[AuthorizationPolicy:<br/>allow-nothing]
    C1 --> C1B[AuthorizationPolicy:<br/>allow-in-ns]
    C1 --> C1C[AuthorizationPolicy:<br/>additional]
    C1 --> C1D[AuthorizationPolicy:<br/>from-netpol]

    C2 --> C2A[Sidecar]
    C2 --> C2C[AuthorizationPolicy:<br/>custom]
    C2 --> C2D[ServiceEntry:<br/>custom]

    C3 --> C3A[PeerAuthentication]

    %% Styling
    classDef configKeys fill:#e1f5fe,stroke:#01579b,stroke-width:2px,color:black;
    classDef resources fill:#f3e5f5,stroke:#4a148c,stroke-width:2px,color:black;
    classDef subKeys fill:#fff3e0,stroke:#e65100,stroke-width:2px,color:black;
    classDef defaults fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px,color:black;

    class C configKeys;
    class C1,C2,C3 subKeys;
    class C1A,C1B,C2A,C3A defaults;
    class C1C,C1D,C2B,C2C,C2D resources;
```
